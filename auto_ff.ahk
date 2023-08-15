
global TotalPhys,TotalPhy
VarSetCapacity( MEMORYSTATUSEX,64,0 ), NumPut( 64,MEMORYSTATUSEX )
DllCall( "GlobalMemoryStatusEx", UInt,&MEMORYSTATUSEX )
TotalPhys := NumGet( MEMORYSTATUSEX,8,"Int64"),  VarSetCapacity( PhysMem,16,0 )
DllCall( "shlwapi.dll\StrFormatByteSize64A", Int64,TotalPhys, Str,PhysMem, UInt,16 )
ON:
#SingleInstance ignore
#NoEnv
#Persistent
#KeyHistory 0
#NoTrayIcon
#Warn All, Off
ListLines, OFF
SetBatchLines, -1
SetWinDelay, 0
SetControlDelay, 0
DetectHiddenText, On
DetectHiddenWindows, On
CoordMode, Mouse, Client
CoordMode, pixel, Client
SetKeyDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetTitleMatchMode, 3
class _ClassMemory
{
static baseAddress, hProcess, PID, currentProgram
, insertNullTerminator := True
, readStringLastError := False
, isTarget64bit := False
, ptrType := "UInt"
, aTypeSize := {    "UChar":    1,  "Char":     1
,   "UShort":   2,  "Short":    2
,   "UInt":     4,  "Int":      4
,   "UFloat":   4,  "Float":    4
,   "Int64":    8,  "Double":   8}
, aRights := {  "PROCESS_ALL_ACCESS": 0x001F0FFF
,   "PROCESS_CREATE_PROCESS": 0x0080
,   "PROCESS_CREATE_THREAD": 0x0002
,   "PROCESS_DUP_HANDLE": 0x0040
,   "PROCESS_QUERY_INFORMATION": 0x0400
,   "PROCESS_QUERY_LIMITED_INFORMATION": 0x1000
,   "PROCESS_SET_INFORMATION": 0x0200
,   "PROCESS_SET_QUOTA": 0x0100
,   "PROCESS_SUSPEND_RESUME": 0x0800
,   "PROCESS_TERMINATE": 0x0001
,   "PROCESS_VM_OPERATION": 0x0008
,   "PROCESS_VM_READ": 0x0010
,   "PROCESS_VM_WRITE": 0x0020
,   "SYNCHRONIZE": 0x00100000}
__new(program, dwDesiredAccess := "", byRef handle := "", windowMatchMode := 3)
{
if this.PID := handle := this.findPID(program, windowMatchMode)
{
if dwDesiredAccess is not integer
dwDesiredAccess := this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_VM_OPERATION | this.aRights.PROCESS_VM_READ | this.aRights.PROCESS_VM_WRITE
dwDesiredAccess |= this.aRights.SYNCHRONIZE
if this.hProcess := handle := this.OpenProcess(this.PID, dwDesiredAccess)
{
this.pNumberOfBytesRead := DllCall("GlobalAlloc", "UInt", 0x0040, "Ptr", A_PtrSize, "Ptr")
this.pNumberOfBytesWritten := DllCall("GlobalAlloc", "UInt", 0x0040, "Ptr", A_PtrSize, "Ptr")
this.readStringLastError := False
this.currentProgram := program
if this.isTarget64bit := this.isTargetProcess64Bit(this.PID, this.hProcess, dwDesiredAccess)
this.ptrType := "Int64"
else this.ptrType := "UInt"
if (A_PtrSize != 4 || !this.isTarget64bit)
this.BaseAddress := this.getModuleBaseAddress()
if this.BaseAddress < 0 || !this.BaseAddress
this.BaseAddress := this.getProcessBaseAddress(program, windowMatchMode)
Return, this
}
}
return
}
__delete()
{
this.closeHandle(this.hProcess)
if this.pNumberOfBytesRead
DllCall("GlobalFree", "Ptr", this.pNumberOfBytesRead)
if this.pNumberOfBytesWritten
DllCall("GlobalFree", "Ptr", this.pNumberOfBytesWritten)
return
}
findPID(program, windowMatchMode := "3")
{
if RegExMatch(program, "i)\s*AHK_PID\s+(0x[[:xdigit:]]+|\d+)", pid)
Return, pid1
if windowMatchMode
{
mode := A_TitleMatchMode
StringReplace, windowMatchMode, windowMatchMode, 0x
SetTitleMatchMode, %windowMatchMode%
}
WinGet, pid, pid, %program%
if windowMatchMode
SetTitleMatchMode, %mode%
if (!pid && RegExMatch(program, "i)\bAHK_EXE\b\s*(.*)", fileName))
{
filename := RegExReplace(filename1, "i)\bahk_(class|id|pid|group)\b.*", "")
filename := trim(filename)
SplitPath, fileName, fileName
if (fileName)
{
Process, Exist, %fileName%
pid := ErrorLevel
}
}
Return, pid ? pid : 0
}
isHandleValid()
{
Return, 0x102 = DllCall("WaitForSingleObject", "Ptr", this.hProcess, "UInt", 0)
}
openProcess(PID, dwDesiredAccess)
{
r := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr")
if (!r && A_LastError = 5)
{
this.setSeDebugPrivilege(true)
if (r2 := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr"))
Return, r2
DllCall("SetLastError", "UInt", 5)
}
Return, r ? r : ""
}
closeHandle(hProcess)
{
Return, DllCall("CloseHandle", "Ptr", hProcess)
}
numberOfBytesRead()
{
Return, !this.pNumberOfBytesRead ? -1 : NumGet(this.pNumberOfBytesRead+0, "Ptr")
}
numberOfBytesWritten()
{
Return, !this.pNumberOfBytesWritten ? -1 : NumGet(this.pNumberOfBytesWritten+0, "Ptr")
}
read(address, type := "UInt", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
Return, "", ErrorLevel := -2
if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", result, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesRead)
Return, result
return
}
readRaw(address, byRef buffer, bytes := 4, aOffsets*)
{
VarSetCapacity(buffer, bytes)
Return, DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", bytes, "Ptr", this.pNumberOfBytesRead)
}
readString(address, sizeBytes := 0, encoding := "UTF-8", aOffsets*)
{
bufferSize := VarSetCapacity(buffer, sizeBytes ? sizeBytes : 100, 0)
this.ReadStringLastError := False
if aOffsets.maxIndex()
address := this.getAddressFromOffsets(address, aOffsets*)
if !sizeBytes
{
if (encoding = "utf-16" || encoding = "cp1200")
encodingSize := 2, charType := "UShort", loopCount := 2
else encodingSize := 1, charType := "Char", loopCount := 4
Loop
{
if !DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address + ((outterIndex := A_index) - 1) * 4, "Ptr", &buffer, "Ptr", 4, "Ptr", this.pNumberOfBytesRead) || ErrorLevel
Return, "", this.ReadStringLastError := True
else loop, %loopCount%
{
if NumGet(buffer, (A_Index - 1) * encodingSize, charType) = 0
{
if (bufferSize < sizeBytes := outterIndex * 4 - (4 - A_Index * encodingSize))
VarSetCapacity(buffer, sizeBytes)
Break, 2
}
}
}
}
if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesRead)
Return, StrGet(&buffer,, encoding)
Return, "", this.ReadStringLastError := True
}
writeString(address, string, encoding := "utf-8", aOffsets*)
{
encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
VarSetCapacity(buffer, requiredSize)
StrPut(string, &buffer, StrLen(string) + (this.insertNullTerminator ?  1 : 0), encoding)
Return, DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", requiredSize, "Ptr", this.pNumberOfBytesWritten)
}
write(address, value, type := "Uint", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
Return, "", ErrorLevel := -2
Return, DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", value, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesWritten)
}
writeRaw(address, pBuffer, sizeBytes, aOffsets*)
{
Return, DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", pBuffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesWritten)
}
writeBytes(address, hexStringOrByteArray, aOffsets*)
{
if !IsObject(hexStringOrByteArray)
{
if !IsObject(hexStringOrByteArray := this.hexStringToPattern(hexStringOrByteArray))
Return, hexStringOrByteArray
}
sizeBytes := this.getNeedleFromAOBPattern("", buffer, hexStringOrByteArray*)
Return, this.writeRaw(address, &buffer, sizeBytes, aOffsets*)
}
pointer(address, finalType := "UInt", offsets*)
{
For index, offset in offsets
address := this.Read(address, this.ptrType) + offset
Return, this.Read(address, finalType)
}
getAddressFromOffsets(address, aOffsets*)
{
Return, aOffsets.Remove() + this.pointer(address, this.ptrType, aOffsets*)
}
getProcessBaseAddress(windowTitle, windowMatchMode := "3")
{
if (windowMatchMode && A_TitleMatchMode != windowMatchMode)
{
mode := A_TitleMatchMode
StringReplace, windowMatchMode, windowMatchMode, 0x
SetTitleMatchMode, %windowMatchMode%
}
WinGet, hWnd, ID, %WindowTitle%
if mode
SetTitleMatchMode, %mode%
if !hWnd
return
Return, DllCall(A_PtrSize = 4 ? "GetWindowLong" : "GetWindowLongPtr", "Ptr", hWnd, "Int", -6, A_Is64bitOS ? "Int64" : "UInt")
}
getModuleBaseAddress(moduleName := "", byRef aModuleInfo := "")
{
aModuleInfo := ""
if (moduleName = "")
moduleName := this.GetModuleFileNameEx(0, True)
if r := this.getModules(aModules, True) < 0
Return, r
Return, aModules.HasKey(moduleName) ? (aModules[moduleName].lpBaseOfDll, aModuleInfo := aModules[moduleName]) : -1
}
getModuleFromAddress(address, byRef aModuleInfo, byRef offsetFromModuleBase := "")
{
aModuleInfo := offsetFromModule := ""
if result := this.getmodules(aModules) < 0
Return, result
for k, module in aModules
{
if (address >= module.lpBaseOfDll && address < module.lpBaseOfDll + module.SizeOfImage)
Return, 1, aModuleInfo := module, offsetFromModuleBase := address - module.lpBaseOfDll
}
Return, -1
}
setSeDebugPrivilege(enable := True)
{
h := DllCall("OpenProcess", "UInt", 0x0400, "Int", false, "UInt", DllCall("GetCurrentProcessId"), "Ptr")
DllCall("Advapi32.dll\OpenProcessToken", "Ptr", h, "UInt", 32, "PtrP", t)
VarSetCapacity(ti, 16, 0)
NumPut(1, ti, 0, "UInt")
DllCall("Advapi32.dll\LookupPrivilegeValue", "Ptr", 0, "Str", "SeDebugPrivilege", "Int64P", luid)
NumPut(luid, ti, 4, "Int64")
if enable
NumPut(2, ti, 12, "UInt")
r := DllCall("Advapi32.dll\AdjustTokenPrivileges", "Ptr", t, "Int", false, "Ptr", &ti, "UInt", 0, "Ptr", 0, "Ptr", 0)
DllCall("CloseHandle", "Ptr", t)
DllCall("CloseHandle", "Ptr", h)
Return, r
}
isTargetProcess64Bit(PID, hProcess := "", currentHandleAccess := "")
{
if !A_Is64bitOS
Return, False
else if !hProcess || !(currentHandleAccess & (this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_QUERY_LIMITED_INFORMATION))
closeHandle := hProcess := this.openProcess(PID, this.aRights.PROCESS_QUERY_INFORMATION)
if (hProcess && DllCall("IsWow64Process", "Ptr", hProcess, "Int*", Wow64Process))
result := !Wow64Process
Return, result, closeHandle ? this.CloseHandle(hProcess) : ""
}
suspend()
{
Return, DllCall("ntdll\NtSuspendProcess", "Ptr", this.hProcess)
}
resume()
{
Return, DllCall("ntdll\NtResumeProcess", "Ptr", this.hProcess)
}
getModules(byRef aModules, useFileNameAsKey := False)
{
if (A_PtrSize = 4 && this.IsTarget64bit)
Return, -4
aModules := []
if !moduleCount := this.EnumProcessModulesEx(lphModule)
Return, -3
loop % moduleCount
{
this.GetModuleInformation(hModule := numget(lphModule, (A_index - 1) * A_PtrSize), aModuleInfo)
aModuleInfo.Name := this.GetModuleFileNameEx(hModule)
filePath := aModuleInfo.name
SplitPath, filePath, fileName
aModuleInfo.fileName := fileName
if useFileNameAsKey
aModules[fileName] := aModuleInfo
else aModules.insert(aModuleInfo)
}
Return, moduleCount
}
getEndAddressOfLastModule(byRef aModuleInfo := "")
{
if !moduleCount := this.EnumProcessModulesEx(lphModule)
Return, -3
hModule := numget(lphModule, (moduleCount - 1) * A_PtrSize)
if this.GetModuleInformation(hModule, aModuleInfo)
Return, aModuleInfo.lpBaseOfDll + aModuleInfo.SizeOfImage
Return, -5
}
GetModuleFileNameEx(hModule := 0, fileNameNoPath := False)
{
VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
DllCall("psapi\GetModuleFileNameEx", "Ptr", this.hProcess, "Ptr", hModule, "Str", lpFilename, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
if fileNameNoPath
SplitPath, lpFilename, lpFilename
Return, lpFilename
}
EnumProcessModulesEx(byRef lphModule, dwFilterFlag := 0x03)
{
lastError := A_LastError
size := VarSetCapacity(lphModule, 4)
loop
{
DllCall("psapi\EnumProcessModulesEx", "Ptr", this.hProcess, "Ptr", &lphModule, "Uint", size, "Uint*", reqSize, "Uint", dwFilterFlag)
if ErrorLevel
Return, 0
else if (size >= reqSize)
break
else size := VarSetCapacity(lphModule, reqSize)
}
DllCall("SetLastError", "UInt", lastError)
Return, reqSize // A_PtrSize
}
GetModuleInformation(hModule, byRef aModuleInfo)
{
VarSetCapacity(MODULEINFO, A_PtrSize * 3), aModuleInfo := []
Return, DllCall("psapi\GetModuleInformation", "Ptr", this.hProcess, "Ptr", hModule, "Ptr", &MODULEINFO, "UInt", A_PtrSize * 3), aModuleInfo := {  lpBaseOfDll: numget(MODULEINFO, 0, "Ptr"),   SizeOfImage: numget(MODULEINFO, A_PtrSize, "UInt"),   EntryPoint: numget(MODULEINFO, A_PtrSize * 2, "Ptr") }
}
hexStringToPattern(hexString)
{
AOBPattern := []
hexString := RegExReplace(hexString, "(\s|0x)")
StringReplace, hexString, hexString, ?, ?, UseErrorLevel
wildCardCount := ErrorLevel
if !length := StrLen(hexString)
Return, -1
else if RegExMatch(hexString, "[^0-9a-fA-F?]")
Return, -2
else if Mod(wildCardCount, 2)
Return, -3
else if Mod(length, 2)
Return, -4
loop, % length/2
{
value := "0x" SubStr(hexString, 1 + 2 * (A_index-1), 2)
AOBPattern.Insert(value + 0 = "" ? "?" : value)
}
Return, AOBPattern
}
stringToPattern(string, encoding := "UTF-8", insertNullTerminator := False)
{
if !length := StrLen(string)
Return, -1
AOBPattern := []
encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
requiredSize := StrPut(string, encoding) * encodingSize - (insertNullTerminator ? 0 : encodingSize)
VarSetCapacity(buffer, requiredSize)
StrPut(string, &buffer, length + (insertNullTerminator ?  1 : 0), encoding)
loop, % requiredSize
AOBPattern.Insert(NumGet(buffer, A_Index-1, "UChar"))
Return, AOBPattern
}
modulePatternScan(module := "", aAOBPattern*)
{
MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000, PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100
if (result := this.getModuleBaseAddress(module, aModuleInfo)) <= 0
Return, "", ErrorLevel := result
if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
Return, -10
if (result := this.PatternScan(aModuleInfo.lpBaseOfDll, aModuleInfo.SizeOfImage, patternMask, AOBBuffer)) >= 0
Return, result
address := aModuleInfo.lpBaseOfDll
endAddress := address + aModuleInfo.SizeOfImage
loop
{
if !this.VirtualQueryEx(address, aRegion)
Return, -9
if (aRegion.State = MEM_COMMIT
&& !(aRegion.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aRegion.RegionSize >= patternSize
&& (result := this.PatternScan(address, aRegion.RegionSize, patternMask, AOBBuffer)) > 0)
Return, result
}
until (address += aRegion.RegionSize) >= endAddress
Return, 0
}
addressPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
Return, -10
Return, this.PatternScan(startAddress, sizeOfRegionBytes, patternMask, AOBBuffer)
}
processPatternScan(startAddress := 0, endAddress := "", aAOBPattern*)
{
address := startAddress
if endAddress is not integer
endAddress := this.isTarget64bit ? (A_PtrSize = 8 ? 0x7FFFFFFFFFF : 0xFFFFFFFF) : 0x7FFFFFFF
MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000
PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100
if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
Return, -10
while address <= endAddress
{
if !this.VirtualQueryEx(address, aInfo)
Return, -1
if A_Index = 1
aInfo.RegionSize -= address - aInfo.BaseAddress
if (aInfo.State = MEM_COMMIT)
&& !(aInfo.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aInfo.RegionSize >= patternSize
&& (result := this.PatternScan(address, aInfo.RegionSize, patternMask, AOBBuffer))
{
if result < 0
Return, -2
else if (result + patternSize - 1 <= endAddress)
Return, result
else return 0
}
address += aInfo.RegionSize
}
Return, 0
}
rawPatternScan(byRef buffer, sizeOfBufferBytes := "", startOffset := 0, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
Return, -10
if (sizeOfBufferBytes + 0 = "" || sizeOfBufferBytes <= 0)
sizeOfBufferBytes := VarSetCapacity(buffer)
if (startOffset + 0 = "" || startOffset < 0)
startOffset := 0
Return, this.bufferScanForMaskedPattern(&buffer, sizeOfBufferBytes, patternMask, &AOBBuffer, startOffset)
}
getNeedleFromAOBPattern(byRef patternMask, byRef needleBuffer, aAOBPattern*)
{
patternMask := "", VarSetCapacity(needleBuffer, aAOBPattern.MaxIndex())
for i, v in aAOBPattern
patternMask .= (v + 0 = "" ? "?" : "x"), NumPut(round(v), needleBuffer, A_Index - 1, "UChar")
Return, round(aAOBPattern.MaxIndex())
}
VirtualQueryEx(address, byRef aInfo)
{
if (aInfo.__Class != "_ClassMemory._MEMORY_BASIC_INFORMATION")
aInfo := new this._MEMORY_BASIC_INFORMATION()
Return, aInfo.SizeOfStructure = DLLCall("VirtualQueryEx", "Ptr", this.hProcess, "Ptr", address, "Ptr", aInfo.pStructure, "Ptr", aInfo.SizeOfStructure, "Ptr")
}
patternScan(startAddress, sizeOfRegionBytes, byRef patternMask, byRef needleBuffer)
{
if !this.readRaw(startAddress, buffer, sizeOfRegionBytes)
Return, -1
if (offset := this.bufferScanForMaskedPattern(&buffer, sizeOfRegionBytes, patternMask, &needleBuffer)) >= 0
Return, startAddress + offset
else return 0
}
bufferScanForMaskedPattern(hayStackAddress, sizeOfHayStackBytes, byRef patternMask, needleAddress, startOffset := 0)
{
static p
if !p
{
if A_PtrSize = 4
p := this.MCode("1,x86:8B44240853558B6C24182BC5568B74242489442414573BF0773E8B7C241CBB010000008B4424242BF82BD8EB038D49008B54241403D68A0C073A0A740580383F750B8D0C033BCD74174240EBE98B442424463B74241876D85F5E5D83C8FF5BC35F8BC65E5D5BC3")
else
p := this.MCode("1,x64:48895C2408488974241048897C2418448B5424308BF2498BD8412BF1488BF9443BD6774A4C8B5C24280F1F800000000033C90F1F400066660F1F840000000000448BC18D4101418D4AFF03C80FB60C3941380C18740743803C183F7509413BC1741F8BC8EBDA41FFC2443BD676C283C8FF488B5C2408488B742410488B7C2418C3488B5C2408488B742410488B7C2418418BC2C3")
}
if (needleSize := StrLen(patternMask)) + startOffset > sizeOfHayStackBytes
Return, -1
if (sizeOfHayStackBytes > 0)
Return, DllCall(p, "Ptr", hayStackAddress, "UInt", sizeOfHayStackBytes, "Ptr", needleAddress, "UInt", needleSize, "AStr", patternMask, "UInt", startOffset, "cdecl int")
Return, -2
}
MCode(mcode)
{
static e := {1:4, 2:1}, c := (A_PtrSize=8) ? "x64" : "x86"
if !regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m)
return
if !DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0)
return
p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
if DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0)
Return, p
DllCall("GlobalFree", "ptr", p)
return
}
class _MEMORY_BASIC_INFORMATION
{
__new()
{
if !this.pStructure := DllCall("GlobalAlloc", "UInt", 0, "Ptr", this.SizeOfStructure := A_PtrSize = 8 ? 48 : 28, "Ptr")
Return, ""
Return, this
}
__Delete()
{
DllCall("GlobalFree", "Ptr", this.pStructure)
}
__get(key)
{
static aLookUp := A_PtrSize = 8
?   {   "BaseAddress": {"Offset": 0, "Type": "Int64"}
,    "AllocationBase": {"Offset": 8, "Type": "Int64"}
,    "AllocationProtect": {"Offset": 16, "Type": "UInt"}
,    "RegionSize": {"Offset": 24, "Type": "Int64"}
,    "State": {"Offset": 32, "Type": "UInt"}
,    "Protect": {"Offset": 36, "Type": "UInt"}
,    "Type": {"Offset": 40, "Type": "UInt"}	}
:   {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
,   "RegionSize": {"Offset": 12, "Type": "UInt"}
,   "State": {"Offset": 16, "Type": "UInt"}
,   "Protect": {"Offset": 20, "Type": "UInt"}
,   "Type": {"Offset": 24, "Type": "UInt"} }
if aLookUp.HasKey(key)
Return, numget(this.pStructure+0, aLookUp[key].Offset, aLookUp[key].Type)
}
__set(key, value)
{
static aLookUp := A_PtrSize = 8
?   {   "BaseAddress": {"Offset": 0, "Type": "Int64"}
,    "AllocationBase": {"Offset": 8, "Type": "Int64"}
,    "AllocationProtect": {"Offset": 16, "Type": "UInt"}
,    "RegionSize": {"Offset": 24, "Type": "Int64"}
,    "State": {"Offset": 32, "Type": "UInt"}
,    "Protect": {"Offset": 36, "Type": "UInt"}
,    "Type": {"Offset": 40, "Type": "UInt"}	}
:   {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
,   "RegionSize": {"Offset": 12, "Type": "UInt"}
,   "State": {"Offset": 16, "Type": "UInt"}
,   "Protect": {"Offset": 20, "Type": "UInt"}
,   "Type": {"Offset": 24, "Type": "UInt"} }
if aLookUp.HasKey(key)
{
NumPut(value, this.pStructure+0, aLookUp[key].Offset, aLookUp[key].Type)
Return, value
}
}
Ptr()
{
Return, this.pStructure
}
sizeOf()
{
Return, this.SizeOfStructure
}
}
}
global jelan,jPID,jTitle,pwb,MapNumber,RunDirect,NowDate,Version,lov,identt,bann,byte,bytes
global Location,MsgMacro,State,Inven,Buy,Repair,Ras,SelectRas,Map,AAD,MapSize,GAD,Weapon,Chat,Attack,Mount,NPCMenu,AAS,PosX,PosY,MovePosX,MCC,BAI,MovePosY,NowHP,HCC,AAI,MaxHP,NowMP,MaxMP,NowFP,MaxFP,Gold,AGI,FormNumber,NPCMsg,NPCMenuBuyPosX,SCC,CTC,NPCMenuBuyPosY,DCC,NPCMenuRepairPosX,BAD,NPCMenuRepairPosY,rCTC,AbilityNameADD,SSC,AbilityValueADD,BAS,AbilityName,SSS,AbilityValue,Moving,Slot1Ability,GAI,SST,Slot2Ability,Slot3Ability,GAS,Slot4Ability,HPPercent,FPPercent,Shield,StatePosX,StatePosY,CheckFirstHP,CheckUPHP,RunningTime,ChangeValue,MagicN,Slot1Ability,Slot2Ability,Slot3Ability,Slot4Ability,Slot5Ability,Slot6Ability,Slot7Ability,Slot8Ability,Slot9Ability,Slot10Ability,Slot11Ability,Slot12Ability,Slot13Ability,Slot14Ability,Slot15Ability,Slot16Ability,Slot17Ability,Slot18Ability,Slot19Ability,Slot20Ability,Slot1AN,Slot2AN,Slot3AN,Slot4AN,Slot5AN,Slot6AN,Slot7AN,Slot8AN,Slot9AN,Slot10AN,Slot11AN,Slot12AN,Slot13AN,Slot14AN,Slot15AN,Slot16AN,Slot17AN,Slot18AN,Slot19AN,Slot20AN,CritHP,CritMP,Get_CharOID,CharID_1,CharID_2,CharID_3,CharID_4,CharID_5,CharID_6,ChangeValue,pP1,pP2,pP3,pP4,pP5,pP6,P1,P2,P3,P4,P5,P6,loady,ProgramStartTime,RPST,RPST,BasicWValue0,BasicWValue1,BasicWValue2,BasicWValue3,BWValue0,BWValue1,BWValue2,BWValue3,RMNS,MNS,RMNN,Slot3MN,Slot4MN,Slot5MN,Slot6MN,Slot7MN,Slot8MN,Slot3Magic,Slot4Magic,Slot5Magic,Slot6Magic,Slot7Magic,Slot8Magic,MLimit,incinerateitem,RowNumber,inciNumber = 1,inciItem,CCD,CheckPB,newTime1,nowtime1,nowtime,RCC,pbtalkcheck1,pbtalkcheck2
global npcServer
Gui, -MaximizeBox -MinimizeBox
Gui, Add, Tab, x0 y4 w690 h670, 설정|Ability|Utility
Gui, Add, Checkbox, x590 y2 w110 h18  vGui_relogerror, 재접속 오류
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x10 y30 w330 h135, 로그인 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x30 y55 +Left, ID
Gui, Add, Text, x30 y80 +Left, PW
Gui, Add, Edit, x110 y52 w140 +Left vGui_NexonID
Gui, Add, Edit, x110 y77 w140 +Left Password vGui_NexonPassWord
Gui, Font
Gui, Font, s10 Bold
Gui, Add, Button, x260 y51 w70 h45 +Center vGui_StartButton gStart, 시작
Gui, Font
Gui, Font, s8
Gui, Add, Text, x30 y115 +Left, 서버
Gui, Add, Text, x30 y140 +Left, 캐릭터번호
Gui, Add, DropDownList, x110 y112 w140 +Left vGui_Server, 엘|테스
Gui, Add, DropDownList, x110 y137 w140 +Left vGui_CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Font
Gui, Font, s10 Bold
Gui, Add, Button, x260 y111 w70 h45 +Center vGui_Resetting gResetting, 리셋
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x350 y30 w330 h150, 포남 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x370 y50 +Left, 만드 체크
Gui, Add, Checkbox, x450 y48 h15 vGui_EvadeMand, 주위에 만드가 있으면 다른몹 찾기
Gui, Add, Text, x370 y75 +Left, 동선 설정
Gui, Add, Radio, x450 y73 h15 Checked vGui_MoveLoute1, 시계
Gui, Add, Radio, x500 y73 h15 vGui_MoveLoute2, 반시계
Gui, Add, Radio, x560 y73 h15 vGui_MoveLoute3, 가로
Gui, Add, Radio, x610 y73 h15 vGui_MoveLoute4, 반가로
Gui, Add, Text, x370 y100 +Left, 몬스터 설정
Gui, Add, Radio, x450 y98 h15 Checked vGui_Ent gCheckMob, 엔트
Gui, Add, Radio, x500 y98 h15 vGui_Rockey gCheckMob, 록키
Gui, Add, Radio, x570 y98 h15 vGui_EntRockey gCheckMob, 엔트록키
Gui, Add, Radio, x450 y123 h15 vGui_Mand gCheckMob, 만드
Gui, Add, Radio, x400 y123 h15 vGui_MobMagic gCheckMob, 마법
Gui, Add, Radio, x500 y123 h15 vGui_AllMobAND gCheckMob, 전체AND
Gui, Add, Radio, x570 y123 h15 vGui_AllMobOR gCheckMob, 전체OR
Gui, Add, Text, x370 y155 +Left, 전체 몬스터 선택시 어빌
Gui, Add, Edit, x495 y152 w35 +Right Limit4 number Disabled vGui_AllMobLimit, 9200
Gui, Add, Text, x535 y155 +Left, 이상이면 만드만 공격
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x350 y185 w330 h125, 공통 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x370 y203 +Left, 체작 장소
Gui, Add, Radio, x450 y200 h15 Checked vGui_HuntAuto gSelectHuntPlace, 자동
Gui, Add, Radio, x510 y200 h15 vGui_HuntPonam gSelectHuntPlace, 포남
Gui, Add, Radio, x570 y200 h15 vGui_HuntPobuk gSelectHuntPlace, 포북
Gui, Add, Text, x370 y225 w25, 격투
Gui, Add, Text, x435 y225 w25, 1번
Gui, Add, Text, x500 y225 w25, 2번
Gui, Add, Text, x565 y225 w25, 3번
Gui, Add, Edit, x395 y222 w35 +Center Limit5 number Disabled vGui_LimitAbility0, 9200
Gui, Add, Edit, x460 y222 w35 +Center Limit5 number vGui_LimitAbility1, 9200
Gui, Add, Edit, x525 y222 w35 +Center Limit5 number Disabled vGui_LimitAbility2, 9200
Gui, Add, Edit, x590 y222 w35 +Center Limit5 number Disabled vGui_LimitAbility3, 9200
Gui, Add, Text, x370 y250 +Left, 파티 설정
Gui, Add, Radio, x450 y247 h15 vGui_PartyOn Checked, 허용
Gui, Add, Radio, x510 y247 h15 vGui_PartyOff, 거부
Gui, Add, Text, x370 y270 +Left, 자동 그레이드
Gui, Add, Checkbox, x450 y268 h15 vGui_Grade
Gui, Add, Text, x370 y290 +Left, 강제 그레이드
Gui, Add, Button, x535 y284 w40 h21 +Center vGui_FG gforcegrade, 실행
Gui, Add, DropDownList, x450 y285 w80 +Left vGui_forceweapon, 선택|격투|검|단검|도|도끼|거대도끼|대검|대도|창, 특수창|봉, 해머|현금|활|거대검|거대도|양손단검|양손도끼|스태프
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x10 y170 w330 h81, HP 설정
Gui, Font
Gui, Font, s8
Gui, Add, Checkbox, x30 y186 w15 h15 gCheckUseHPExit vGui_CheckUseHPExit
Gui, Add, Checkbox, x30 y208 w15 h15 gCheckUseHPPortal vGui_CheckUseHPPortal
Gui, Add, Checkbox, x30 y230 w15 h15 gCheckUseHPLimited vGui_CheckUseHPLimited
Gui, Add, Text, x55 y188 +Left, 체력이
Gui, Add, Text, x55 y210 +Left, 체력이
Gui, Add, Text, x55 y232 +Left, 체력이
Gui, Add, Edit, x95 y183 w50 +Right Limit6 number Disabled cRed vGui_HPExit, 0
Gui, Add, Edit, x95 y205 w50 +Right Limit6 number Disabled cRed vGui_HPPortal, 0
Gui, Add, Edit, x95 y227 w50 +Right Limit6 number Disabled cRed vGui_HPLimited, 0
Gui, Add, Text, x150 y188 +Left, 이하시 종료 ( 재접속 하지 않음 )
Gui, Add, Text, x150 y210 +Left, 이하시 차원이동
Gui, Add, Text, x150 y232 +Left, 도달시 종료 ( 재접속 하지 않음 )
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x10 y253 w330 h122, 무바 설정
Gui, Font
Gui, Font, s8
Gui, Add, Radio, x30 y275 h15 Checked vGui_1Muba gSelectMuba, 1무바
Gui, Add, Radio, x130 y275 h15 vGui_2Muba gSelectMuba, 2무바
Gui, Add, Radio, x230 y275 h15 vGui_3Muba gSelectMuba, 3무바
Gui, Add, Radio, x30 y300 h15 vGui_2ButMuba gSelectMuba, 2벗무바
Gui, Add, Radio, x130 y300 h15 vGui_3ButMuba gSelectMuba, 3벗무바
Gui, Add, Radio, x230 y300 h15 vGui_4ButMuba gSelectMuba, 4벗무바
Gui, Add, Text, x35 y330 +Left, 1번 무기어빌
Gui, Add, Text, x135 y330 +Left, 2번 무기어빌
Gui, Add, Text, x235 y330 +Left, 3번 무기어빌
Gui, Add, DropDownList, x30 y345 w80 +Left vGui_Weapon1 gSelectAbility, 검|단검|도|도끼|대검|대도|창, 특수창|봉, 해머|현금|활|거대검|거대도|거대도끼|양손단검|양손도끼|스태프
Gui, Add, DropDownList, x130 y345 w80 +Left Disabled vGui_Weapon2 gSelectAbility, 검|단검|도|도끼|대검|대도|창, 특수창|봉, 해머|현금|활|거대검|거대도|거대도끼|양손단검|양손도끼|스태프
Gui, Add, DropDownList, x230 y345 w80 +Left Disabled vGui_Weapon3 gSelectAbility, 검|단검|도|도끼|대검|대도|창, 특수창|봉, 해머|현금|활|거대검|거대도|거대도끼|양손단검|양손도끼|스태프
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x10 y380 w170 h55, 라깃 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x30 y405 +Left, 라스의깃 갯수
Gui, Add, Edit, x105 y402 w30 +Right Limit3 number vGui_RasCount, 0
Gui, Add, Text, x140 y405 +Left, 개
Gui, Font
Gui, Font, s9
Gui, Add, Button, x152 y397 w16 h13 +Center  glagitu, ∧
Gui, Add, Button, x152 y413 w16 h13 +Center  glagitd, ∨
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x185 y380 w155 h55, 줍줍/소각 설정
Gui, Font
Gui, Font, s8
Gui, Font
Gui, Font, s9 cBlue Bold
Gui, Add, Radio, x203 y405 w60 vGui_jjON, ON
Gui, Font
Gui, Font, s9 cRed Bold
Gui, Add, Radio, x263 y405 w60 vGui_jjOFF, OFF
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x350 y320 w330 h175, 캐릭터 상태
Gui, Font
Gui, Font, s8
Gui, Add, Text, x360 y345 w60 +Right, 캐릭터명 :
Gui, Add, Text, x360 y370 w60 +Right, 진행상황 :
Gui, Add, Text, x360 y395 w60 +Right, 지역 :
Gui, Add, Text, x360 y420 w60 +Right, 갈리드 :
Gui, Add, Text, x360 y445 w60 +Right, HP :
Gui, Add, Text, x360 y470 w60 +Right, FP :
Gui, Add, Text, x445 y345 w220 vGui_CharName
Gui, Add, Text, x445 y370 w220 vGui_NowState
Gui, Add, Text, x445 y395 w220 vGui_NowLocation
Gui, Add, Text, x445 y420 w220 vGui_NowGold
Gui, Add, Text, x445 y445 w220 cRed vGui_NowHP
Gui, Add, Text, x445 y470 w220 cBlue vGui_NowFP
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x10 y445 w330 h95, 어빌리티
Gui, Font
Gui, Font, s8
Gui, Add, Text, x90 y465 w55 +Center, 격투
Gui, Add, Text, x150 y465 w55 +Center, 1번
Gui, Add, Text, x210 y465 w55 +Center, 2번
Gui, Add, Text, x265 y465 w55 +Center, 3번
Gui, Add, Text, x20 y490, 어빌리티
Gui, Add, Text, x20 y515, 어빌레벨
Gui, Font, s8
Gui, Add, Text, x90 y490 w55 +Center vGui_BasicWName0
Gui, Add, Text, x150 y490 w55 +Center vGui_BasicWName1
Gui, Add, Text, x210 y490 w55 +Center vGui_BasicWName2
Gui, Add, Text, x265 y490 w55 +Center vGui_BasicWName3
Gui, Add, Text, x90 y515 w55 +Center vGui_BasicWValue0
Gui, Add, Text, x150 y515 w55 +Center vGui_BasicWValue1
Gui, Add, Text, x210 y515 w55 +Center vGui_BasicWValue2
Gui, Add, Text, x265 y515 w55 +Center vGui_BasicWValue3
Gui, Font
Gui, Font, s8 cGreen Bold
Gui, Add, GroupBox, x350 y495 w330 h45, 감응 설정
Gui, Font
Gui, Font, s9 cBlue Bold
Gui, Add, Radio, x450 y515 w60 vGui_KON, ON
Gui, Font
Gui, Font, s9 cRed Bold
Gui, Add, Radio, x520 y515 w60 vGui_KOFF, OFF
Gui, Font
Gui, Font, s8
Gui, Add, StatusBar, , 시작대기중
Gui, Tab, Ability
Gui, Font
Gui, Font, s8 Bold
Gui, Add, GroupBox, x10 y30 w670 h308, 어빌리티
Gui, Font
Gui, Font, s8
Gui, Add, Text, x98 y55 +Center, 어빌 1슬롯
Gui, Add, Text, x196 y55 +Center, 어빌 2슬롯
Gui, Add, Text, x294 y55 +Center, 어빌 3슬롯
Gui, Add, Text, x392 y55 +Center, 어빌 4슬롯
Gui, Add, Text, x490 y55 +Center, 어빌 5슬롯
Gui, Add, edit, x84 y75 w80 +Left Disabled vGui_WeaponName1
Gui, Add, edit, x182 y75 w80 +Left Disabled vGui_WeaponName2
Gui, Add, edit, x280 y75 w80 +Left Disabled vGui_WeaponName3
Gui, Add, edit, x378 y75 w80 +Left Disabled vGui_WeaponName4
Gui, Add, edit, x476 y75 w80 +Left Disabled vGui_WeaponName5
Gui, Add, edit, x84 y98 w80 +Left Disabled vGui_WeaponValue1
Gui, Add, edit, x182 y98 w80 +Left Disabled vGui_WeaponValue2
Gui, Add, edit, x280 y98 w80 +Left Disabled vGui_WeaponValue3
Gui, Add, edit, x378 y98 w80 +Left Disabled vGui_WeaponValue4
Gui, Add, edit, x476 y98 w80 +Left Disabled vGui_WeaponValue5
Gui, Add, Checkbox, x83 y53 w15 h15 gCheckW1 vGui_WeaponCheck1
Gui, Add, Checkbox, x181 y53 w15 h15 gCheckW2 vGui_WeaponCheck2
Gui, Add, Checkbox, x279 y53 w15 h15 gCheckW3 vGui_WeaponCheck3
Gui, Add, Checkbox, x377 y53 w15 h15 gCheckW4 vGui_WeaponCheck4
Gui, Add, Checkbox, x475 y53 w15 h15 gCheckW5 vGui_WeaponCheck5
Gui, Add, Text, x98 y125 +Center, 어빌 6슬롯
Gui, Add, Text, x196 y125 +Center, 어빌 7슬롯
Gui, Add, Text, x294 y125 +Center, 어빌 8슬롯
Gui, Add, Text, x392 y125 +Center, 어빌 9슬롯
Gui, Add, Text, x490 y125 +Center, 어빌 10슬롯
Gui, Add, edit, x84 y145 w80 +Left Disabled vGui_WeaponName6
Gui, Add, edit, x182 y145 w80 +Left Disabled vGui_WeaponName7
Gui, Add, edit, x280 y145 w80 +Left Disabled vGui_WeaponName8
Gui, Add, edit, x378 y145 w80 +Left Disabled vGui_WeaponName9
Gui, Add, edit, x476 y145 w80 +Left Disabled vGui_WeaponName10
Gui, Add, edit, x84 y168 w80 +Left Disabled vGui_WeaponValue6
Gui, Add, edit, x182 y168 w80 +Left Disabled vGui_WeaponValue7
Gui, Add, edit, x280 y168 w80 +Left Disabled vGui_WeaponValue8
Gui, Add, edit, x378 y168 w80 +Left Disabled vGui_WeaponValue9
Gui, Add, edit, x476 y168 w80 +Left Disabled vGui_WeaponValue10
Gui, Add, Checkbox, x83 y123 w15 h15 gCheckW6 vGui_WeaponCheck6
Gui, Add, Checkbox, x181 y123 w15 h15 gCheckW7 vGui_WeaponCheck7
Gui, Add, Checkbox, x279 y123 w15 h15 gCheckW8 vGui_WeaponCheck8
Gui, Add, Checkbox, x377 y123 w15 h15 gCheckW9 vGui_WeaponCheck9
Gui, Add, Checkbox, x475 y123 w15 h15 gCheckW10 vGui_WeaponCheck10
Gui, Add, Text, x98 y195 +Center, 어빌11슬롯
Gui, Add, Text, x196 y195 +Center, 어빌12슬롯
Gui, Add, Text, x294 y195 +Center, 어빌13슬롯
Gui, Add, Text, x392 y195 +Center, 어빌14슬롯
Gui, Add, Text, x490 y195 +Center, 어빌15슬롯
Gui, Add, edit, x84 y215 w80 +Left Disabled vGui_WeaponName11
Gui, Add, edit, x182 y215 w80 +Left Disabled vGui_WeaponName12
Gui, Add, edit, x280 y215 w80 +Left Disabled vGui_WeaponName13
Gui, Add, edit, x378 y215 w80 +Left Disabled vGui_WeaponName14
Gui, Add, edit, x476 y215 w80 +Left Disabled vGui_WeaponName15
Gui, Add, edit, x84 y238 w80 +Left Disabled vGui_WeaponValue11
Gui, Add, edit, x182 y238 w80 +Left Disabled vGui_WeaponValue12
Gui, Add, edit, x280 y238 w80 +Left Disabled vGui_WeaponValue13
Gui, Add, edit, x378 y238 w80 +Left Disabled vGui_WeaponValue14
Gui, Add, edit, x476 y238 w80 +Left Disabled vGui_WeaponValue15
Gui, Add, Checkbox, x83 y193 w15 h15 gCheckW11 vGui_WeaponCheck11
Gui, Add, Checkbox, x181 y193 w15 h15 gCheckW12 vGui_WeaponCheck12
Gui, Add, Checkbox, x279 y193 w15 h15 gCheckW13 vGui_WeaponCheck13
Gui, Add, Checkbox, x377 y193 w15 h15 gCheckW14 vGui_WeaponCheck14
Gui, Add, Checkbox, x475 y193 w15 h15 gCheckW15 vGui_WeaponCheck15
Gui, Add, Text, x98 y265 +Center, 어빌16슬롯
Gui, Add, Text, x196 y265 +Center, 어빌17슬롯
Gui, Add, Text, x294 y265 +Center, 어빌18슬롯
Gui, Add, Text, x392 y265 +Center, 어빌19슬롯
Gui, Add, Text, x490 y265 +Center, 어빌20슬롯
Gui, Add, edit, x84 y285 w80 +Left Disabled vGui_WeaponName16
Gui, Add, edit, x182 y285 w80 +Left Disabled vGui_WeaponName17
Gui, Add, edit, x280 y285 w80 +Left Disabled vGui_WeaponName18
Gui, Add, edit, x378 y285 w80 +Left Disabled vGui_WeaponName19
Gui, Add, edit, x476 y285 w80 +Left Disabled vGui_WeaponName20
Gui, Add, edit, x84 y308 w80 +Left Disabled vGui_WeaponValue16
Gui, Add, edit, x182 y308 w80 +Left Disabled vGui_WeaponValue17
Gui, Add, edit, x280 y308 w80 +Left Disabled vGui_WeaponValue18
Gui, Add, edit, x378 y308 w80 +Left Disabled vGui_WeaponValue19
Gui, Add, edit, x476 y308 w80 +Left Disabled vGui_WeaponValue20
Gui, Add, Checkbox, x83 y263 w15 h15 gCheckW16 vGui_WeaponCheck16
Gui, Add, Checkbox, x181 y263 w15 h15 gCheckW17 vGui_WeaponCheck17
Gui, Add, Checkbox, x279 y263 w15 h15 gCheckW18 vGui_WeaponCheck18
Gui, Add, Checkbox, x377 y263 w15 h15 gCheckW19 vGui_WeaponCheck19
Gui, Add, Checkbox, x475 y263 w15 h15 gCheckW20 vGui_WeaponCheck20
Gui, Font
Gui, Font, s8 Bold
Gui, Add, GroupBox, x10 y338 w670 h188, 스펠
Gui, Font
Gui, Font, s8
Gui, Add, Text, x68 y363 +Center, 스펠 3슬롯
Gui, Add, Text, x166 y363 +Center, 스펠 4슬롯
Gui, Add, Text, x264 y363 +Center, 스펠 5슬롯
Gui, Add, Text, x362 y363 +Center, 스펠 6슬롯
Gui, Add, Text, x460 y363 +Center, 스펠 7슬롯
Gui, Add, Text, x558 y363 +Center, 스펠 8슬롯
Gui, Add, edit, x54 y383 w80 +Left Disabled vGui_MagicName3
Gui, Add, edit, x152 y383 w80 +Left Disabled vGui_MagicName4
Gui, Add, edit, x250 y383 w80 +Left Disabled vGui_MagicName5
Gui, Add, edit, x348 y383 w80 +Left Disabled vGui_MagicName6
Gui, Add, edit, x446 y383 w80 +Left Disabled vGui_MagicName7
Gui, Add, edit, x544 y383 w80 +Left Disabled vGui_MagicName8
Gui, Add, edit, x54 y406 w80 +Left Disabled vGui_MagicValue3
Gui, Add, edit, x152 y406 w80 +Left Disabled vGui_MagicValue4
Gui, Add, edit, x250 y406 w80 +Left Disabled vGui_MagicValue5
Gui, Add, edit, x348 y406 w80 +Left Disabled vGui_MagicValue6
Gui, Add, edit, x446 y406 w80 +Left Disabled vGui_MagicValue7
Gui, Add, edit, x544 y406 w80 +Left Disabled vGui_MagicValue8
Gui, Add, Checkbox, x53 y361 w15 h15 gCheckM3 vGui_MagicCheck3
Gui, Add, Checkbox, x151 y361 w15 h15 gCheckM4 vGui_MagicCheck4
Gui, Add, Checkbox, x249 y361 w15 h15 gCheckM5 vGui_MagicCheck5
Gui, Add, Checkbox, x347 y361 w15 h15 gCheckM6 vGui_MagicCheck6
Gui, Add, Checkbox, x445 y361 w15 h15 gCheckM7 vGui_MagicCheck7
Gui, Add, Checkbox, x543 y361 w15 h15 gCheckM8 vGui_MagicCheck8
Gui, Tab, Utility
Gui, Font, s8 Bold
Gui, Add, Checkbox, x30 y55 w15 h15 vGui_CheckUseParty
Gui, Add, GroupBox, x10 y30 w220 h205, 파티 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x55 y57 +Left, 체크시 원격파티 사용
Gui, Add, Text, x15 y78, 파티장
Gui, add, Edit, x65 y75 w100 vName1
Gui, Add, DropDownList, x178 y75 w38 +Left vGui_P1CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Add, Text, x15 y103, 파티원
Gui, add, Edit, x65 y100 w100 vName2
Gui, Add, DropDownList, x178 y100 w38 +Left vGui_P2CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Add, Text, x15 y128, 파티원
Gui, add, Edit, x65 y125 w100 vName3
Gui, Add, DropDownList, x178 y125 w38 +Left vGui_P3CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Add, Text, x15 y153, 파티원
Gui, add, Edit, x65 y150 w100 vName4
Gui, Add, DropDownList, x178 y150 w38 +Left vGui_P4CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Add, Text, x15 y178, 파티원
Gui, add, Edit, x65 y175 w100 vName5
Gui, Add, DropDownList, x178 y175 w38 +Left vGui_P5CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Add, Text, x15 y203, 파티원
Gui, add, Edit, x65 y200 w100 vName6
Gui, Add, DropDownList, x178 y200 w38 +Left vGui_P6CharNumber, 1|2|3|4|5|6|7|8|9|10
Gui, Font, s8 Bold
Gui, Add, GroupBox, x235 y30 w220 h205, 마법 설정
Gui, Font
Gui, Font, s8
Gui, Add, Text, x280 y57 +Left, 체크시 원격마법 사용
Gui, Add, Checkbox, x255 y55 w15 h15 gCheckUseMagic vGui_CheckUseMagic
Gui, Add, Text, x150 y220 +Left
Gui, Add, Text, x240 y78 +Left, 회복HP
Gui, Add, Edit, x295 y75 w80 +Right Limit7 number cRed vGui_CHP, 0
Gui, Add, Text, x240 y103 +Left, 스펠슬롯
Gui, Add, DropDownList, x295 y100 w80 +Left vGui_MagicNStack, 3|4|5|6|7|8
Gui, Add, Text, x378 y103 +Left, 번 까지 사용
Gui, Add, Text, x240 y128 +Left, 1번 (엘)리메듐
Gui, Add, Text, x240 y153 +Left, 2번 브렐
Gui, Font, s8 Bold
Gui, Add, GroupBox, x460 y30 w220 h205, 포남 소각 설정
Gui, Font
Gui, Font, s8
Gui, Add, ListView, x465 y50 h145 w200 -Multi vincinerateitemPN, 아이템
Gui, add, Edit, x465 y200 w100 vGui_incinerateitem
Gui, Add, Button, x570 y200 w40 h20 gAddincinerate, 추가
Gui, Add, Button, x613 y200 w40 h20 gDelincinerate, 삭제
LV_ModifyCol(1, 150)
Gui, Font, s8 Bold
Gui, Add, GroupBox, x460 y250 w220 h205, 포북 소각 설정
Gui, Font
Gui, Font, s8
Gui, Add, ListView, x465 y270 h145 w200 -Multi vincinerateitemPB, 아이템
Gui, add, Edit, x465 y420 w100 vGui_incinerateitem2
Gui, Add, Button, x570 y420 w40 h20 gAddincinerate2, 추가
Gui, Add, Button, x613 y420 w40 h20 gDelincinerate2, 삭제
LV_ModifyCol(1, 150)
Gui, Font
Gui, Show, x0 y0 w690 h565, 엘원격체잠
GuiControl, , Name1, 파티원
GuiControl, , Name2, 파티원
GuiControl, , Name3, 파티원
GuiControl, , Name4, 파티원
GuiControl, , Name5, 파티원
GuiControl, , Name6, 파티원
RegRead, RegUseHPExit, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPExit
RegRead, RegUseMagic, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMagic
RegRead, RegHPExit, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPExit
RegRead, RegUseHPPortal, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPPortal
RegRead, RegHPPortal, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPPortal
RegRead, RegUseHPLimited, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPLimited
RegRead, RegHPLimited, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPLimited
RegRead, RegCritHP, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CrittHP
RegRead, RegMuba, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba
RegRead, RegRasCount, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, RasCount
RegRead, RegWeapon1, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon1
RegRead, RegWeapon2, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon2
RegRead, RegWeapon3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon3
RegRead, RegUseParty, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseParty
RegRead, RegP1, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P1
RegRead, RegP2, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P2
RegRead, RegP3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P3
RegRead, RegP4, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P4
RegRead, RegP5, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P5
RegRead, RegP6, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P6
RegRead, RegN1, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N1
RegRead, RegN2, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N2
RegRead, RegN3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N3
RegRead, RegN4, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N4
RegRead, RegN5, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N5
RegRead, RegN6, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N6
RegRead, RegID, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, ID
RegRead, RegRelog, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, relog
RegRead, RegUseWC1, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC1
RegRead, RegUseWC2, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC2
RegRead, RegUseWC3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC3
RegRead, RegUseWC4, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC4
RegRead, RegUseWC5, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC5
RegRead, RegUseWC6, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC6
RegRead, RegUseWC7, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC7
RegRead, RegUseWC8, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC8
RegRead, RegUseWC9, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC9
RegRead, RegUseWC10, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC10
RegRead, RegUseWC11, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC11
RegRead, RegUseWC12, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC12
RegRead, RegUseWC13, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC13
RegRead, RegUseWC14, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC14
RegRead, RegUseWC15, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15
RegRead, RegUseWC16, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC16
RegRead, RegUseWC17, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC17
RegRead, RegUseWC18, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC18
RegRead, RegUseWC19, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC19
RegRead, RegUseWC20, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC20
RegRead, RegUseMC3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC3
RegRead, RegUseMC4, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC4
RegRead, RegUseMC5, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC5
RegRead, RegUseMC6, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC6
RegRead, RegUseMC7, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC7
RegRead, RegUseMC8, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC8
RegRead, RegPass, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Pass
RegRead, RegServer, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Server
RegRead, RegCharNumber, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CharNumber
RegRead, RegMNS, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, MNS
RegRead, RegEvade, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Evade
RegRead, RegDirect, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct
RegRead, RegKONOFF, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, KONOFF
RegRead, RegjjONOFF, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, jjONOFF
RegRead, RegMonster, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster
RegRead, RegAllMobLimit, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, AllMobLimit
RegRead, RegPlace, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place
RegRead, RegLimit0, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit0
RegRead, RegLimit1, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit1
RegRead, RegLimit2, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit2
RegRead, RegLimit3, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit3
RegRead, RegParty, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Party
RegRead, RegGrade, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Grade
RegRead, Regloady, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, loady
RegRead, RegPST, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, StartTime
RegRead, RegCFH, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CFH
ttgm = 0
GuiControl, , Gui_NexonID, %RegID%
GuiControl, Choose, Gui_CharNumber, %RegCharNumber%
GuiControl, Choose, Gui_Server, %RegServer%
if(Regloady = 1)
{
GuiControl, , Gui_NexonPassWord, %RegPass%
RPST := RegPST
RCFH := RegCFH
ttgm = 1
loady = 2
}
if(RegUseHPExit = 1)
{
GuiControl, , Gui_CheckUseHPExit, 1
GuiControl, Enable, Gui_HPExit
}
if(RegUseHPLimited = 1)
{
GuiControl, , Gui_CheckUseHPLimited, 1
GuiControl, Enable, Gui_HPLimited
}
if(RegUseMagic = 1)
{
GuiControl, , Gui_CheckUseMagic, 1
}
if(RegUseParty = 1)
{
GuiControl, , Gui_CheckUseParty, 1
}
if(RegUseParty = 0)
{
GuiControl, , Gui_CheckUseParty, 0
}
if(RegUseHPPortal = 1)
{
GuiControl, , Gui_CheckUseHPPortal, 1
GuiControl, Enable, Gui_HPPortal
}
if(RegHPLimited != "")
{
GuiControl, , Gui_HPLimited, %RegHPLimited%
}
if(RegHPExit != "")
{
GuiControl, , Gui_HPExit, %RegHPExit%
}
if(RegCritHP != "")
{
GuiControl, , Gui_CHP, %RegCritHP%
}
if(RegRasCount != "")
{
GuiControl, , Gui_RasCount, %RegRasCount%
}
if(RegHPPortal != "")
{
GuiControl, , Gui_HPPortal, %RegHPPortal%
}
if(RegMuba = 1 or RegMuba = 4)
{
if(RegMuba = 1)
{
GuiControl, , Gui_1Muba, 1
}
if(RegP1 != "")
{
GuiControl, , Name1, %RegP1%
GuiControl, Choose, Gui_P1CharNumber, %RegN1%
}
if(RegP2 != "")
{
GuiControl, , Name2, %RegP2%
GuiControl, Choose, Gui_P2CharNumber, %RegN2%
}
if(RegP3 != "")
{
GuiControl, , Name3, %RegP3%
GuiControl, Choose, Gui_P3CharNumber, %RegN3%
}
if(RegP4 != "")
{
GuiControl, , Name4, %RegP4%
GuiControl, Choose, Gui_P4CharNumber, %RegN4%
}
if(RegP5 != "")
{
GuiControl, , Name5, %RegP5%
GuiControl, Choose, Gui_P5CharNumber, %RegN5%
}
if(RegP6 != "")
{
GuiControl, , Name6, %RegP6%
GuiControl, Choose, Gui_P6CharNumber, %RegN6%
}
if(RegMuba = 4)
{
GuiControl, , Gui_2ButMuba, 1
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %RegWeapon1%
}
if(RegMuba = 2 or RegMuba = 5)
{
if(RegMuba = 2)
{
GuiControl, , Gui_2Muba, 1
}
if(RegMuba = 5)
{
GuiControl, , Gui_3ButMuba, 1
}
GuiControl, Enable, Gui_Weapon2
if(RegMuba = 5)
{
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %RegWeapon1%
GuiControl, , Gui_BasicWName2, %RegWeapon2%
}
if(RegMuba = 3 or RegMuba = 6)
{
if(RegMuba = 3)
{
GuiControl, , Gui_3Muba, 1
}
if(RegMuba = 6)
{
GuiControl, , Gui_4ButMuba, 1
}
GuiControl, Enable, Gui_Weapon2
GuiControl, Enable, Gui_Weapon3
if(RegMuba = 6)
{
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %RegWeapon1%
GuiControl, , Gui_BasicWName2, %RegWeapon2%
GuiControl, , Gui_BasicWName3, %RegWeapon3%
}
GuiControl, Choose, Gui_Weapon1, %RegWeapon1%
GuiControl, Choose, Gui_Weapon2, %RegWeapon2%
GuiControl, Choose, Gui_Weapon3, %RegWeapon3%
if(RegEvade = 1)
{
GuiControl, , Gui_EvadeMand, 1
}
if(RegDirect = 2)
{
GuiControl, , Gui_MoveLoute2, 1
}
if(RegDirect = 3)
{
GuiControl, , Gui_MoveLoute3, 1
}
if(RegDirect = 4)
{
GuiControl, , Gui_MoveLoute4, 1
}
if(RegKONOFF = 1)
{
GuiControl, , Gui_KON, 1
}
if(RegKONOFF = 2)
{
GuiControl, , Gui_KOFF, 1
}
if(RegjjONOFF = 1)
{
GuiControl, , Gui_jjON, 1
}
if(RegjjONOFF = 2)
{
GuiControl, , Gui_jjOFF, 1
}
if(RegMonster = 1)
{
GuiControl, , Gui_Ent, 1
}
if(RegMonster = 2)
{
GuiControl, , Gui_Rockey, 1
}
if(RegMonster = 3)
{
GuiControl, , Gui_EntRockey, 1
}
if(RegMonster = 4)
{
GuiControl, , Gui_Mand, 1
}
if(RegMonster = 5)
{
GuiControl, , Gui_AllMobAND, 1
}
if(RegMonster = 6)
{
GuiControl, , Gui_AllMobOR, 1
}
if(RegMonster = 7)
{
GuiControl, , Gui_MobMagic, 1
}
if(RegAllMobLimit != "")
{
GuiControl, , Gui_AllMobLimit, %RegAllMobLimit%
}
if(RegMonster >= 4 and RegMonster <= 7)
{
GuiControl, , Gui_EvadeMand, 0
GuiControl, Disable, Gui_EvadeMand
}
if(RegMonster >= 5 and RegMonster <= 7)
{
GuiControl, Enable, Gui_AllMobLimit
}
if(RegPlace = 1)
{
if(RegMuba = 2)
{
GuiControl, Enable, Gui_LimitAbility2
}
if(RegMuba = 3)
{
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
}
if(RegMuba = 4)
{
GuiControl, Enable, Gui_LimitAbility0
}
if(RegMuba = 5)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility2
}
if(RegMuba = 6)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
}
}
if(RegPlace = 2)
{
GuiControl, , Gui_HuntPonam, 1
GuiControl, Disable, Gui_LimitAbility1
}
if(RegPlace = 3)
{
GuiControl, , Gui_HuntPobuk, 1
GuiControl, Disable, Gui_LimitAbility1
}
if(RegLimit0 != "")
{
GuiControl, , Gui_LimitAbility0, %RegLimit0%
GuiControl, , Gui_LimitAbility1, %RegLimit1%
GuiControl, , Gui_LimitAbility2, %RegLimit2%
GuiControl, , Gui_LimitAbility3, %RegLimit3%
}
if(RegParty = 1)
{
GuiControl, , Gui_PartyOn, 1
}
if(RegParty = 2)
{
GuiControl, , Gui_PartyOff, 1
}
if(RegGrade = 1)
{
GuiControl, , Gui_Grade, 1
}
if(RegP1 != "")
{
GuiControl, , Name1, %RegP1%
GuiControl, Choose, Gui_P1CharNumber, %RegN1%
}
if(RegP2 != "")
{
GuiControl, , Name2, %RegP2%
GuiControl, Choose, Gui_P2CharNumber, %RegN2%
}
if(RegP3 != "")
{
GuiControl, , Name3, %RegP3%
GuiControl, Choose, Gui_P3CharNumber, %RegN3%
}
if(RegP4 != "")
{
GuiControl, , Name4, %RegP4%
GuiControl, Choose, Gui_P4CharNumber, %RegN4%
}
if(RegP5 != "")
{
GuiControl, , Name5, %RegP5%
GuiControl, Choose, Gui_P5CharNumber, %RegN5%
}
if(RegP6 != "")
{
GuiControl, , Name6, %RegP6%
GuiControl, Choose, Gui_P6CharNumber, %RegN6%
}
RMNS := RegMNS
RMNSF := RMNS - 2
GuiControl, Choose, Gui_MagicNStack, %RMNSF%
GuiControlGet, RMNN, , Gui_MagicNStack
if(RegUseWC1 = 1)
{
GuiControl, , Gui_WeaponCheck1, 1
}
if(RegUseWC1 = 0)
{
GuiControl, , Gui_WeaponCheck1, 0
}
if(RegUseWC2 = 1)
{
GuiControl, , Gui_WeaponCheck2, 1
}
if(RegUseWC2 = 0)
{
GuiControl, , Gui_WeaponCheck2, 0
}
if(RegUseWC3 = 1)
{
GuiControl, , Gui_WeaponCheck3, 1
}
if(RegUseWC3 = 0)
{
GuiControl, , Gui_WeaponCheck3, 0
}
if(RegUseWC4 = 1)
{
GuiControl, , Gui_WeaponCheck4, 1
}
if(RegUseWC4 = 0)
{
GuiControl, , Gui_WeaponCheck4, 0
}
if(RegUseWC5 = 1)
{
GuiControl, , Gui_WeaponCheck5, 1
}
if(RegUseWC5 = 0)
{
GuiControl, , Gui_WeaponCheck5, 0
}
if(RegUseWC6 = 1)
{
GuiControl, , Gui_WeaponCheck6, 1
}
if(RegUseWC6 = 0)
{
GuiControl, , Gui_WeaponCheck6, 0
}
if(RegUseWC7 = 1)
{
GuiControl, , Gui_WeaponCheck7, 1
}
if(RegUseWC7 = 0)
{
GuiControl, , Gui_WeaponCheck7, 0
}
if(RegUseWC8 = 1)
{
GuiControl, , Gui_WeaponCheck8, 1
}
if(RegUseWC8 = 0)
{
GuiControl, , Gui_WeaponCheck8, 0
}
if(RegUseWC9 = 1)
{
GuiControl, , Gui_WeaponCheck9, 1
}
if(RegUseWC9 = 0)
{
GuiControl, , Gui_WeaponCheck9, 0
}
if(RegUseWC10 = 1)
{
GuiControl, , Gui_WeaponCheck10, 1
}
if(RegUseWC10 = 0)
{
GuiControl, , Gui_WeaponCheck10, 0
}
if(RegUseWC11 = 1)
{
GuiControl, , Gui_WeaponCheck11, 1
}
if(RegUseWC11 = 0)
{
GuiControl, , Gui_WeaponCheck11, 0
}
if(RegUseWC12 = 1)
{
GuiControl, , Gui_WeaponCheck12, 1
}
if(RegUseWC12 = 0)
{
GuiControl, , Gui_WeaponCheck12, 0
}
if(RegUseWC13 = 1)
{
GuiControl, , Gui_WeaponCheck13, 1
}
if(RegUseWC13 = 0)
{
GuiControl, , Gui_WeaponCheck13, 0
}
if(RegUseWC14 = 1)
{
GuiControl, , Gui_WeaponCheck14, 1
}
if(RegUseWC14 = 0)
{
GuiControl, , Gui_WeaponCheck14, 0
}
if(RegUseWC15 = 1)
{
GuiControl, , Gui_WeaponCheck15, 1
}
if(RegUseWC15 = 0)
{
GuiControl, , Gui_WeaponCheck15, 0
}
if(RegUseWC16 = 1)
{
GuiControl, , Gui_WeaponCheck16, 1
}
if(RegUseWC16 = 0)
{
GuiControl, , Gui_WeaponCheck16, 0
}
if(RegUseWC17 = 1)
{
GuiControl, , Gui_WeaponCheck17, 1
}
if(RegUseWC17 = 0)
{
GuiControl, , Gui_WeaponCheck17, 0
}
if(RegUseWC18 = 1)
{
GuiControl, , Gui_WeaponCheck18, 1
}
if(RegUseWC18 = 0)
{
GuiControl, , Gui_WeaponCheck18, 0
}
if(RegUseWC19 = 1)
{
GuiControl, , Gui_WeaponCheck19, 1
}
if(RegUseWC19 = 0)
{
GuiControl, , Gui_WeaponCheck19, 0
}
if(RegUseWC20 = 1)
{
GuiControl, , Gui_WeaponCheck20, 1
}
if(RegUseWC20 = 0)
{
GuiControl, , Gui_WeaponCheck20, 0
}
if(RegUseMC3 = 1)
{
GuiControl, , Gui_MagicCheck3, 1
}
if(RegUseMC3 = 0)
{
GuiControl, , Gui_MagicCheck3, 0
}
if(RegUseMC4 = 1)
{
GuiControl, , Gui_MagicCheck4, 1
}
if(RegUseMC4 = 0)
{
GuiControl, , Gui_MagicCheck4, 0
}
if(RegUseMC5 = 1)
{
GuiControl, , Gui_MagicCheck5, 1
}
if(RegUseMC5 = 0)
{
GuiControl, , Gui_MagicCheck5, 0
}
if(RegUseMC6 = 1)
{
GuiControl, , Gui_MagicCheck6, 1
}
if(RegUseMC6 = 0)
{
GuiControl, , Gui_MagicCheck6, 0
}
if(RegUseMC7 = 1)
{
GuiControl, , Gui_MagicCheck7, 1
}
if(RegUseMC7 = 0)
{
GuiControl, , Gui_MagicCheck7, 0
}
if(RegUseMC8 = 1)
{
GuiControl, , Gui_MagicCheck8, 1
}
if(RegUseMC8 = 0)
{
GuiControl, , Gui_MagicCheck8, 0
}
if(RegRelog = 1)
{
GuiControl, , Gui_relogerror, 1
}
if(RegRelog = 0)
{
GuiControl, , Gui_relogerror, 0
}
Gui, listview, incinerateitemPN
Loop, Read, C:\Nexon\Elancia\incipn.ini
{
LV_Add(A_Index, A_LoopReadLine)
}
Gui, listview, incinerateitemPB
Loop, Read, C:\Nexon\Elancia\incipb.ini
{
LV_Add(A_Index, A_LoopReadLine)
}
Gui, Margin, 0, 0
Gui, Color, White
Gui, -MinimizeBox -MaximizeBox +LastFound
Gui_ID := WinExist()
Gui, Submit, Nohide
GuiControl, choose, Gui_forceweapon, 선택
if(loady = 2)
{
Gosub, Start
}
return
lagitu:
Gui, Submit, Nohide
RasCount := Gui_RasCount+1
GuiControl, , Gui_RasCount, %RasCount%
return
lagitd:
Gui, Submit, Nohide
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
return
SelectMuba:
Gui, Submit, Nohide
if(Gui_1Muba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Disable, Gui_Weapon2
GuiControl, Disable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
GuiControl, , Gui_BasicWName0
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2
GuiControl, , Gui_BasicWName3
}
if(Gui_2Muba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
GuiControl, Disable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility3
}
GuiControl, , Gui_BasicWName0
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3
}
if(Gui_3Muba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
GuiControl, Enable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
GuiControl, Disable, Gui_LimitAbility0
}
GuiControl, , Gui_BasicWName0
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3, %Gui_Weapon3%
}
if(Gui_2ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Disable, Gui_Weapon2
GuiControl, Disable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
GuiControl, , Gui_BasicWName0, 격투
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2
GuiControl, , Gui_BasicWName3
}
if(Gui_3ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
GuiControl, Disable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
GuiControl, , Gui_BasicWName0, 격투
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3
}
if(Gui_4ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
GuiControl, Enable, Gui_Weapon3
if(Gui_HuntAuto = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
}
GuiControl, , Gui_BasicWName0, 격투
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3, %Gui_Weapon3%
}
return
SelectAbility:
Gui, Submit, Nohide
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(Gui_1Muba = 1)
{
GuiControl, , Gui_WeaponName0
}
if(Gui_2ButMuba = 1)
{
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2
GuiControl, , Gui_BasicWName3
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(Gui_2Muba = 1)
{
GuiControl, , Gui_WeaponName0
}
if(Gui_3ButMuba = 1)
{
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(Gui_3Muba = 1)
{
GuiControl, , Gui_BasicWName0
}
if(Gui_4ButMuba = 1)
{
GuiControl, , Gui_BasicWName0, 격투
}
GuiControl, , Gui_BasicWName1, %Gui_Weapon1%
GuiControl, , Gui_BasicWName2, %Gui_Weapon2%
GuiControl, , Gui_BasicWName3, %Gui_Weapon3%
}
return
SelectHuntPlace:
Gui, Submit, Nohide
if(Gui_HuntAuto = 1)
{
if(Gui_1Muba = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
if(Gui_2Muba = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility3
}
if(Gui_3Muba = 1)
{
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
GuiControl, Disable, Gui_LimitAbility0
}
if(Gui_2ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
if(Gui_3ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
if(Gui_4ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
}
}
if(Gui_HuntAuto = 0)
{
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
}
return
CheckMob:
Gui, Submit, Nohide
if(Gui_Mand = 1 or Gui_AllMobAND = 1 or Gui_AllMobOR = 1 or Gui_MobMagic = 1)
{
GuiControl, , Gui_EvadeMand, 0
GuiControl, Disable, Gui_EvadeMand
}
if(Gui_AllMobAND = 1 or Gui_AllMobOR = 1 or Gui_MobMagic = 1)
{
GuiControl, Enable, Gui_AllMobLimit
}
if(Gui_AllMobAND = 0 and Gui_AllMobOR = 0 and Gui_MobMagic = 0)
{
GuiControl, Disabled, Gui_AllMobLimit
}
if(Gui_Ent = 1 or Gui_Rockey = 1 or Gui_EntRockey = 1)
{
GuiControl, Enable, Gui_EvadeMand
}
return
CheckUseHPExit:
Gui, Submit, Nohide
GuiControl, % (Gui_CheckUseHPExit ? "enable":"disable"), Gui_HPExit
return
CheckUseHPPortal:
Gui, Submit, Nohide
GuiControl, % (Gui_CheckUseHPPortal ? "enable":"disable"), Gui_HPPortal
return
CheckUseHPLimited:
Gui, Submit, Nohide
GuiControl, % (Gui_CheckUseHPLimited ? "enable":"disable"), Gui_HPLimited
return
CheckUseMagic:
Gui, Submit, Nohide
GuiControl, % (Gui_CheckUseMagic ? "enable":"disable"), Gui_Magic
return
CheckW1:
Gui, Submit, Nohide
if(Gui_WeaponCheck1 = 0)
{
GuiControl, , Gui_WeaponValue1
}
return
CheckW2:
Gui, Submit, Nohide
if(Gui_WeaponCheck2 = 0)
{
GuiControl, , Gui_WeaponValue2
}
return
CheckW3:
Gui, Submit, Nohide
if(Gui_WeaponCheck3 = 0)
{
GuiControl, , Gui_WeaponValue3
}
return
CheckW4:
Gui, Submit, Nohide
if(Gui_WeaponCheck4 = 0)
{
GuiControl, , Gui_WeaponValue4
}
return
CheckW5:
Gui, Submit, Nohide
if(Gui_WeaponCheck5 = 0)
{
GuiControl, , Gui_WeaponValue5
}
return
CheckW6:
Gui, Submit, Nohide
if(Gui_WeaponCheck6 = 0)
{
GuiControl, , Gui_WeaponValue6
}
return
CheckW7:
Gui, Submit, Nohide
if(Gui_WeaponCheck7 = 0)
{
GuiControl, , Gui_WeaponValue7
}
return
CheckW8:
Gui, Submit, Nohide
if(Gui_WeaponCheck8 = 0)
{
GuiControl, , Gui_WeaponValue8
}
return
CheckW9:
Gui, Submit, Nohide
if(Gui_WeaponCheck1 = 9)
{
GuiControl, , Gui_WeaponValue9
}
return
CheckW10:
Gui, Submit, Nohide
if(Gui_WeaponCheck10 = 0)
{
GuiControl, , Gui_WeaponValue10
}
return
CheckW11:
Gui, Submit, Nohide
if(Gui_WeaponCheck11 = 0)
{
GuiControl, , Gui_WeaponValue11
}
return
CheckW12:
Gui, Submit, Nohide
if(Gui_WeaponCheck12 = 0)
{
GuiControl, , Gui_WeaponValue12
}
return
CheckW13:
Gui, Submit, Nohide
if(Gui_WeaponCheck13 = 0)
{
GuiControl, , Gui_WeaponValue13
}
return
CheckW14:
Gui, Submit, Nohide
if(Gui_WeaponCheck14 = 0)
{
GuiControl, , Gui_WeaponValue14
}
return
CheckW15:
Gui, Submit, Nohide
if(Gui_WeaponCheck15 = 0)
{
GuiControl, , Gui_WeaponValue15
}
return
CheckW16:
Gui, Submit, Nohide
if(Gui_WeaponCheck16 = 0)
{
GuiControl, , Gui_WeaponValue16
}
return
CheckW17:
Gui, Submit, Nohide
if(Gui_WeaponCheck17 = 0)
{
GuiControl, , Gui_WeaponValue17
}
return
CheckW18:
Gui, Submit, Nohide
if(Gui_WeaponCheck18 = 0)
{
GuiControl, , Gui_WeaponValue18
}
return
CheckW19:
Gui, Submit, Nohide
if(Gui_WeaponCheck19 = 0)
{
GuiControl, , Gui_WeaponValue19
}
return
CheckW20:
Gui, Submit, Nohide
if(Gui_WeaponCheck20 = 0)
{
GuiControl, , Gui_WeaponValue20
}
return
CheckM3:
Gui, Submit, Nohide
if(Gui_MagicCheck3 = 0)
{
GuiControl, , Gui_MagicValue3
}
return
CheckM4:
Gui, Submit, Nohide
if(Gui_MagicCheck4 = 0)
{
GuiControl, , Gui_MagicValue4
}
return
CheckM5:
Gui, Submit, Nohide
if(Gui_MagicCheck5 = 0)
{
GuiControl, , Gui_MagicValue5
}
return
CheckM6:
Gui, Submit, Nohide
if(Gui_MagicCheck6 = 0)
{
GuiControl, , Gui_MagicValue6
}
return
CheckM7:
if(Gui_MagicCheck7 = 0)
{
Gui, Submit, Nohide
GuiControl, , Gui_MagicValue7
}
return
CheckM8:
Gui, Submit, Nohide
if(Gui_MagicCheck8 = 0)
{
GuiControl, , Gui_MagicValue8
}
return
resetting:
step = 0
return
forcegrade:
step = 700
return
Start:
Gui, Submit, Nohide
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, loady, 0
RegRead, IEVersion, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Internet Explorer\Version Vector, IE
if(IEVersion < 9)
{
SB_SetText("인터넷 버전이 낮습니다.")
return
}
internet := ConnectedToInternet()
if(internet = 0)
{
SB_SetText("인터넷 연결을 확인 해 주세요.")
return
}
if(Gui_NexonID = "")
{
SB_SetText("아이디를 입력 해 주세요.")
return
}
if(Gui_NexonPassWord = "")
{
SB_SetText("패스워드를 입력 해 주세요.")
return
}
if(Gui_Server = "")
{
SB_SetText("서버를 선택 해 주세요.")
return
}
if(Gui_CharNumber = "")
{
SB_SetText("캐릭터번호를 선택 해 주세요.")
return
}
if(Gui_CheckUseHPExit = 1)
{
if(Gui_HPExit = "")
{
SB_SetText("종료 체력을 정확히 입력 해 주세요.")
return
}
if(Gui_HPExit = 0)
{
SB_SetText("종료 체력은 1 이상이여야 합니다.")
return
}
}
if(Gui_CheckUseHPPortal = 1)
{
if(Gui_HPPortal = "")
{
SB_SetText("차원이동 체력을 정확히 입력 해 주세요.")
return
}
if(Gui_HPPortal = 0)
{
SB_SetText("차원이동 체력은 1 이상이여야 합니다.")
return
}
}
if(Gui_CheckUseHPExit = 1 and Gui_CheckUseHPPortal)
{
if(Gui_HPExit > Gui_HPPortal)
{
SB_SetText("차원이동 체력 설정은 종료 체력보다 높아야 합니다.")
return
}
}
if(Gui_AllMobAND = 1 or Gui_AllMobOR = 1)
{
if(Gui_AllMobLimit = "")
{
SB_SetText("전체 몬스터 선택 어빌 제한을 올바르게 설정 해 주세요.")
return
}
if(Gui_AllMobLimit > 9500)
{
SB_SetText("전체 몬스터 선택 어빌 제한은 9500을 넘길 수 없습니다.")
return
}
}
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(Gui_Weapon1 = "")
{
SB_SetText("무기 어빌리티를 올바르게 설정 해 주세요.")
return
}
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(Gui_Weapon1 = "" or Gui_Weapon2 = "")
{
SB_SetText("무기 어빌리티를 올바르게 설정 해 주세요.")
return
}
if(Gui_Weapon1 = Gui_Weapon2)
{
SB_SetText("같은 어빌리티를 선택 할 수 없습니다.")
return
}
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(Gui_Weapon1 = "" or Gui_Weapon2 = "" or Gui_Weapon3 = "")
{
SB_SetText("무기 어빌리티를 올바르게 설정 해 주세요.")
return
}
if(Gui_Weapon1 = Gui_Weapon2 or Gui_Weapon2 = Gui_Weapon3 or Gui_Weapon3 = Gui_Weapon1)
{
SB_SetText("같은 어빌리티를 선택 할 수 없습니다.")
return
}
}
if(Gui_HuntAuto = 1)
{
if(Gui_1Muba = 1)
{
if(Gui_LimitAbility1 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility1 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
if(Gui_2Muba = 1)
{
if(Gui_LimitAbility1 > 9500 or Gui_LimitAbility2 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility1 = "" or Gui_LimitAbility2 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
if(Gui_3Muba = 1)
{
if(Gui_LimitAbility1 > 9500 or Gui_LimitAbility2 > 9500 or Gui_LimitAbility3 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility1 = "" or Gui_LimitAbility2 = "" or Gui_LimitAbility3 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
if(Gui_2ButMuba = 1)
{
if(Gui_LimitAbility0 > 9500 or Gui_LimitAbility1 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility1 = "" or Gui_LimitAbility1 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
if(Gui_3ButMuba = 1)
{
if(Gui_LimitAbility0 > 9500 or Gui_LimitAbility1 > 9500 or Gui_LimitAbility2 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility0 = "" or Gui_LimitAbility1 = "" or Gui_LimitAbility2 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
if(Gui_4ButMuba = 1)
{
if(Gui_LimitAbility0 > 9500 or Gui_LimitAbility1 > 9500 or Gui_LimitAbility2 > 9500 or Gui_LimitAbility3 > 9500)
{
SB_SetText("어빌리티 제한은 9500을 넘길 수 없습니다.")
return
}
if(Gui_LimitAbility0 = "" or Gui_LimitAbility1 = "" or Gui_LimitAbility2 = "" or Gui_LimitAbility3 = "")
{
SB_SetText("어빌리티 제한을 올바르게 설정 해 주세요.")
return
}
}
}
if(Gui_RasCount < 5 or Gui_RasCount = "")
{
SB_SetText("라스의 깃 갯수는 최소 5개 초과이여야 합니다.")
return
}
NexonID := Gui_NexonID
NexonPassword := Gui_NexonPassword
GuiControl, Disable, Gui_NexonID
GuiControl, Disable, Gui_NexonPassWord
GuiControl, Disable, Gui_Server
GuiControl, Disable, Gui_CharNumber
GuiControl, Disable, Gui_CheckUseHPExit
GuiControl, Disable, Gui_CheckUseHPPortal
GuiControl, Disable, Gui_CheckUseHPLimited
GuiControl, Disable, Gui_HPExit
GuiControl, Disable, Gui_HPPortal
GuiControl, Disable, Gui_HPLimited
GuiControl, Disable, Gui_CHP
GuiControl, Disable, Gui_Weapon1
GuiControl, Disable, Gui_Weapon2
GuiControl, Disable, Gui_Weapon3
GuiControl, Disable, Gui_RasCount
GuiControl, Disable, Gui_jjON
GuiControl, Disable, Gui_jjOFF
GuiControl, Disable, Gui_LimitAbility0
GuiControl, Disable, Gui_LimitAbility1
GuiControl, Disable, Gui_LimitAbility2
GuiControl, Disable, Gui_LimitAbility3
GuiControl, Disable, Gui_StartButton
GuiControl, Disable, Gui_WindowSettingButton
GuiControl, Disable, Gui_Agree
SB_SetText("실행중")
Step = 0
FirstCheck = 1
MagicN = 3
FirstPortal = 1
Entrance = 0
ipmak = 0
callid = 1
RCC = 0
ProgramStartTime = 0
if(Regloady = 1)
{
ProgramStartTime := RPST
}
GuiControl, Choose, Gui_Tab, 상태창
loady = 1
SetTimer, Hunt, 50
SetTimer, AttackCheck, 50
SetTimer, RL, 86400000
return
RL:
Gui, Submit, NoHide
loady = 2
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P1, %Name1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P2, %Name2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P3, %Name3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P4, %Name4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P5, %Name5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P6, %Name6%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N1, %Gui_P1CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N2, %Gui_P2CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N3, %Gui_P3CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N4, %Gui_P4CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N5, %Gui_P5CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N6, %Gui_P6CharNumber%
if(Gui_CheckUseHPExit = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPExit, 1
}
if(Gui_CheckUseHPExit = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPExit, 0
}
if(Gui_CheckUseMagic = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMagic, 1
}
if(Gui_CheckUseMagic = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMagic, 0
}
if(Gui_CheckUseParty = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseParty, 1
}
if(Gui_CheckUseParty = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseParty, 0
}
if(Gui_CheckUseHPPortal = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPPortal, 1
}
if(Gui_CheckUseHPPortal = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPPortal, 0
}
if(Gui_CheckUseHPLimited = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPLimited, 1
}
if(Gui_CheckUseHPLimited = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPLimited, 0
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPExit, %Gui_HPExit%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPPortal, %Gui_HPPortal%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPLimited, %Gui_HPLimited%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CrittHP, %Gui_CHP%
if(Gui_1Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 1
}
if(Gui_2Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 2
}
if(Gui_3Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 3
}
if(Gui_2ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 4
}
if(Gui_3ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 5
}
if(Gui_4ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 6
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon1, %Gui_Weapon1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon2, %Gui_Weapon2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon3, %Gui_Weapon3%
if(Gui_EvadeMand = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Evade, 1
}
if(Gui_EvadeMand = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Evade, 0
}
if(Gui_KON = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, KONOFF, 1
}
if(Gui_KOFF = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, KONOFF, 2
}
if(Gui_jjON = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, jjONOFF, 1
}
if(Gui_jjOFF = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, jjONOFF, 2
}
if(Gui_MoveLoute1 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 1
}
if(Gui_MoveLoute2 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 2
}
if(Gui_MoveLoute3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 3
}
if(Gui_MoveLoute4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 4
}
if(Gui_Ent = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 1
}
if(Gui_Rockey= 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 2
}
if(Gui_EntRockey= 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 3
}
if(Gui_Mand = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 4
}
if(Gui_AllMobAND = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 5
}
if(Gui_AllMobOR = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 6
}
if(Gui_MobMagic = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 7
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, AllMobLimit, %Gui_AllMobLimit%
if(Gui_HuntAuto = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 1
}
if(Gui_HuntPonam = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 2
}
if(Gui_HuntPobuk = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 3
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit0, %Gui_LimitAbility0%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit1, %Gui_LimitAbility1%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit2, %Gui_LimitAbility2%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit3, %Gui_LimitAbility3%
if(Gui_PartyOn = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Party, 1
}
if(Gui_PartyOff = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Party, 2
}
if(Gui_Grade = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Grade, 1
}
if(Gui_Grade = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Grade, 0
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, RasCount, %Gui_RasCount%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CharNumber, %Gui_CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, MNS, %Gui_MagicNStack%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Server, %Gui_Server%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, ID, %Gui_NexonID%
if(Gui_WeaponCheck1 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC1, 1
}
if(Gui_WeaponCheck1 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC1, 0
}
if(Gui_WeaponCheck2 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC2, 1
}
if(Gui_WeaponCheck2 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC2, 0
}
if(Gui_WeaponCheck3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC3, 1
}
if(Gui_WeaponCheck3 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC3, 0
}
if(Gui_WeaponCheck4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC4, 1
}
if(Gui_WeaponCheck4 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC4, 0
}
if(Gui_WeaponCheck5 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC5, 1
}
if(Gui_WeaponCheck5 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC5, 0
}
if(Gui_WeaponCheck6 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC6, 1
}
if(Gui_WeaponCheck6 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC6, 0
}
if(Gui_WeaponCheck7 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC7, 1
}
if(Gui_WeaponCheck7 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC7, 0
}
if(Gui_WeaponCheck8 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC8, 1
}
if(Gui_WeaponCheck8 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC8, 0
}
if(Gui_WeaponCheck9 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC9, 1
}
if(Gui_WeaponCheck9 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC9, 0
}
if(Gui_WeaponCheck10 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC10, 1
}
if(Gui_WeaponCheck10 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC10, 0
}
if(Gui_WeaponCheck11 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC11, 1
}
if(Gui_WeaponCheck11 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC11, 0
}
if(Gui_WeaponCheck12 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC12, 1
}
if(Gui_WeaponCheck12 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC12, 0
}
if(Gui_WeaponCheck13 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC13, 1
}
if(Gui_WeaponCheck13 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC13, 0
}
if(Gui_WeaponCheck14 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC14, 1
}
if(Gui_WeaponCheck14 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 0
}
if(Gui_WeaponCheck15 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 1
}
if(Gui_WeaponCheck15 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 0
}
if(Gui_WeaponCheck16 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC16, 1
}
if(Gui_WeaponCheck16 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC16, 0
}
if(Gui_WeaponCheck17 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC17, 1
}
if(Gui_WeaponCheck17 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC17, 0
}
if(Gui_WeaponCheck18 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC18, 1
}
if(Gui_WeaponCheck18 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC18, 0
}
if(Gui_WeaponCheck19 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC19, 1
}
if(Gui_WeaponCheck19 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC19, 0
}
if(Gui_WeaponCheck20 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC20, 1
}
if(Gui_WeaponCheck20 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC20, 0
}
if(Gui_MagicCheck3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC3, 1
}
if(Gui_MagicCheck3 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC3, 0
}
if(Gui_MagicCheck4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC4, 1
}
if(Gui_MagicCheck4 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC4, 0
}
if(Gui_MagicCheck5 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC5, 1
}
if(Gui_MagicCheck5 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC5, 0
}
if(Gui_MagicCheck6 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC6, 1
}
if(Gui_MagicCheck6 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC6, 0
}
if(Gui_MagicCheck7 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC7, 1
}
if(Gui_MagicCheck7 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC7, 0
}
if(Gui_MagicCheck8 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC8, 1
}
if(Gui_MagicCheck8 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC8, 0
}
if(Gui_relogerror = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, relog, 1
}
if(Gui_relogerror = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, relog, 0
}
if(loady = 2)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, loady, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Pass, %Gui_NexonPassWord%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, StartTime, %ProgramStartTime%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CFH, %CheckFirstHP%
}
Gui, submit, nohide
Gui, listview, incinerateitemPN
FileDelete, C:\Nexon\Elancia\incipn.ini
save := LV_GetCount()
loop, %save%{
lv_gettext(savefile1,a_index)
FileAppend, %savefile1%`n, C:\Nexon\Elancia\incipn.ini
}
Sleep, 100
Gui, submit, nohide
Gui, listview, incinerateitemPB
FileDelete, C:\Nexon\Elancia\incipb.ini
save := LV_GetCount()
loop, %save%{
lv_gettext(savefile1,a_index)
FileAppend, %savefile1%`n, C:\Nexon\Elancia\incipb.ini
}
Sleep, 100
Reload
return
Addincinerate:
Gui, Submit, Nohide
Gui, listview, incinerateitemPN
incinerateitem := Gui_incinerateitem
LV_Add("",incinerateitem)
GuiControl, , Gui_incinerateitem
return
Delincinerate:
Gui, Submit, Nohide
Gui, listview, incinerateitemPN
RowNumber = 0
loop
{
RowNumber := LV_GetNext(RowNumber)
if not RowNumber
break
SelectRowNum := RowNumber
}
Lv_Delete(SelectRowNum)
return
Addincinerate2:
Gui, Submit, Nohide
Gui, listview, incinerateitemPB
incinerateitem2 := Gui_incinerateitem2
LV_Add("",incinerateitem2)
GuiControl, , Gui_incinerateitem2
return
Delincinerate2:
Gui, Submit, Nohide
Gui, listview, incinerateitemPB
RowNumber = 0
loop
{
RowNumber := LV_GetNext(RowNumber)
if not RowNumber
break
SelectRowNum := RowNumber
}
Lv_Delete(SelectRowNum)
return
incineration:
Gui, Submit, Nohide
IfInString,Location,포프레스네 남쪽
{
Gui, listview, incinerateitemPN
IfInString,Location,필드
{
Loop % LV_GetCount()
{
LastRowNum := A_index
}
LV_Modify(inciNumber,"Select")
LV_Modify(inciNumber, "Vis")
LV_GetText(inciItem, inciNumber)
Sleep, 10
incinerate_item()
Sleep, 10
incinerate()
inciNumber += 1
if(inciNumber > LastRowNum)
{
inciNumber = 1
}
}
}
IfInString,Location,포프레스네 북쪽
{
Gui, listview, incinerateitemPB
IfInString,Location,필드
{
Loop % LV_GetCount()
{
LastRowNum := A_index
}
LV_Modify(inciNumber,"Select")
LV_Modify(inciNumber, "Vis")
LV_GetText(inciItem, inciNumber)
Sleep, 10
incinerate_item()
Sleep, 10
incinerate()
inciNumber += 1
if(inciNumber > LastRowNum)
{
inciNumber = 1
}
}
}
return
Hunt:
Gui, Submit, Nohide
if(A_WDay = DCC)
{
if(A_hour = HCC)
{
if(A_Min = MCC)
{
GuiControl, , Gui_KOFF, 1
GuiControl, , Gui_NowState, 점검 대기 %SSS%분
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
Sleep, SSC
}
}
}
if(CheckPB = 1)
{
nowtime = %A_Now%
FormatTime, nowtime1, %nowtime%, yyyyMMddHHmm
if(nowtime1 > newTime1)
{
MobNumber = 1
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 1030
}
}
IfWinExist,Microsoft Windows
{
WinClose
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
}
IfWinExist,Microsoft Visual C++ Runtime Library
{
WinClose
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
}
IfWinExist,ahk_exe WerFault.exe
{
ControlClick, Button2, ahk_exe WerFault.exe
Process, Close, WerFault.exe
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
}
IfWinExist, ahk_pid %jPID%
{
if DllCall("IsHungAppWindow", "UInt", WinExist())
Process, Close, %jPID%
}
WinGetText, WindowErrorMsg, ahk_class #32770
IfInString,WindowErrorMsg,프로그램을 마치려면
{
ControlClick, Button1, ahk_class #32770
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
}
IfWinExist,ahk_pid %jPID%
{
if(Step >= 7 and Step < 10000)
{
Get_Location()
GuiControl, , Gui_NowLocation, %Location%
Get_Gold()
GuiControl, , Gui_NowGold, %Gold% 갈리드
Get_HP()
GuiControl,,Gui_NowHP,%NowHP% / %MaxHP% (%HPPercent%`%)
Get_FP()
GuiControl,,Gui_NowFP,%NowFP% / %MaxFP% (%FPPercent%`%)
if(BWValue0 != "")
{
SetFormat, Float, 0.2
TempAbility := BWValue0 / 100
GuiControl, , Gui_BasicWValue0, %TempAbility%
SetFormat, Float, 0
}
if(BWValue1 != "")
{
SetFormat, Float, 0.2
TempAbility := BWValue1 / 100
GuiControl, , Gui_BasicWValue1, %TempAbility%
SetFormat, Float, 0
}
if(BWValue2 != "")
{
SetFormat, Float, 0.2
TempAbility := BWValue2 / 100
GuiControl, , Gui_BasicWValue2, %TempAbility%
SetFormat, Float, 0
}
if(BWValue3 != "")
{
SetFormat, Float, 0.2
TempAbility := BWValue3 / 100
GuiControl, , Gui_BasicWValue3, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility1 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility1 / 100
GuiControl, , Gui_WeaponValue1, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility2 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility2 / 100
GuiControl, , Gui_WeaponValue2, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility3 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility3 / 100
GuiControl, , Gui_WeaponValue3, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility4 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility4 / 100
GuiControl, , Gui_WeaponValue4, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility5 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility5 / 100
GuiControl, , Gui_WeaponValue5, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility6 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility6 / 100
GuiControl, , Gui_WeaponValue6, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility7 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility7 / 100
GuiControl, , Gui_WeaponValue7, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility8 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility8 / 100
GuiControl, , Gui_WeaponValue8, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility9 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility9 / 100
GuiControl, , Gui_WeaponValue9, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility10 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility10 / 100
GuiControl, , Gui_WeaponValue10, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility11 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility11 / 100
GuiControl, , Gui_WeaponValue11, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility12 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility12 / 100
GuiControl, , Gui_WeaponValue12, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility13 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility13 / 100
GuiControl, , Gui_WeaponValue13, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility14 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility14 / 100
GuiControl, , Gui_WeaponValue14, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility15 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility15 / 100
GuiControl, , Gui_WeaponValue15, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility16 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility16 / 100
GuiControl, , Gui_WeaponValue16, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility17 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility17 / 100
GuiControl, , Gui_WeaponValue17, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility18 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility18 / 100
GuiControl, , Gui_WeaponValue18, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility19 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility19 / 100
GuiControl, , Gui_WeaponValue19, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility20 != "")
{
SetFormat, Float, 0.2
TempAbility := WeaponAbility20 / 100
GuiControl, , Gui_WeaponValue20, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility3 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility3
GuiControl, , Gui_MagicValue3, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility4 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility4
GuiControl, , Gui_MagicValue4, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility5 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility5
GuiControl, , Gui_MagicValue5, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility6 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility6
GuiControl, , Gui_MagicValue6, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility7 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility7
GuiControl, , Gui_MagicValue7, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility8 != "")
{
SetFormat, Float, 0.2
TempAbility := MagicAbility8
GuiControl, , Gui_MagicValue8, %TempAbility%
SetFormat, Float, 0
}
if(Regloady = 0)
{
CheckUPHP := MaxHP - CheckFirstHP
}
if(Regloady = 1)
{
CheckUPHP := MaxHP - RCFH
}
RunningTime := FormatSeconds((A_TickCount-ProgramStartTime)/1000)
SB_SetText("시작 체력 : " . CheckFirstHP . " / 상승 체력 : " . CheckUPHP . " / 경과 시간 : " . RunningTime )
if(Gui_CheckUseHPExit = 1)
{
if(NowHP <= Gui_HPExit and NowHP != "")
{
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
GuiControl, , Gui_NowState, 체력이 %NowHP%가 되어 강제 종료 합니다.
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
internet := ConnectedToInternet()
if(internet = 0)
{
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Step = 10000
return
}
ServerMsg := jelan.readString(0x0017E574, 40, "UTF-16", aOffsets*)
IfInString,ServerMsg,서버와의 연결이
{
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
if(Step = 17 or step =18)
{
Entrance += 1
}
if(Entrance > 2)
{
MsgBox, , 비정상종료감지, 감응OFF, 3
GuiControl, , Gui_KOFF, 1
Sleep, 1000
return
}
}
Step = 10000
return
}
if(Gui_CheckUseHPLimited = 1)
{
if(Step >= 7 and Step < 10000)
{
if(MaxHP >= Gui_HPLimited)
{
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
GuiControl, , Gui_NowState, 설정된 체력에 도달하여 강제 종료합니다.
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
}
if(pbtalkcheck != 0)
{
pbtalkcheck2 := A_TickCount - pbtalkcheck1
if(pbtalkcheck2 >= 120000)
{
Sleep, 100
pbtalkcheck = 0
step = 10000
Sleep, 100
}
}
if((Step >= 19 and Step < 90) or Step >= 1016)
{
callid += 1
if(callid > 6000)
{
getNpcidFromFile()
callid = 1
}
}
if((Step >= 19 and Step < 90) or Step >= 1013)
{
if(Gui_1Muba = 1 || Gui_2Muba = 1 || Gui_2ButMuba = 1 || Gui_3ButMuba = 1)
{
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
}
PostMessage, 0x100, 52, 327681, , ahk_pid %jPID%
PostMessage, 0x101, 52, 327681, , ahk_pid %jPID%
PostMessage, 0x100, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x101, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x100, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x100, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x100, 56, 589825, , ahk_pid %jPID%
PostMessage, 0x101, 56, 589825, , ahk_pid %jPID%
Check_SAbilityN()
Check_SAbility()
if(Slot1AN != "")
{
GuiControl, , Gui_WeaponName1, %Slot1AN%
if(Gui_WeaponCheck1 = 1)
{
WeaponAbility1 := Slot1Ability
}
if(Gui_WeaponCheck1 = 0)
{
WeaponAbility1 =
}
}
if(Slot2AN != "")
{
GuiControl, , Gui_WeaponName2, %Slot2AN%
if(Gui_WeaponCheck2 = 1)
{
WeaponAbility2 := Slot2Ability
}
if(Gui_WeaponCheck2 = 0)
{
WeaponAbility2 =
}
}
if(Slot3AN != "")
{
GuiControl, , Gui_WeaponName3, %Slot3AN%
if(Gui_WeaponCheck3 = 1)
{
WeaponAbility3 := Slot3Ability
}
if(Gui_WeaponCheck3 = 0)
{
WeaponAbility3 =
}
}
if(Slot4AN != "")
{
GuiControl, , Gui_WeaponName4, %Slot4AN%
if(Gui_WeaponCheck4 = 1)
{
WeaponAbility4 := Slot4Ability
}
if(Gui_WeaponCheck4 = 0)
{
WeaponAbility4 =
}
}
if(Slot5AN != "")
{
GuiControl, , Gui_WeaponName5, %Slot5AN%
if(Gui_WeaponCheck5 = 1)
{
WeaponAbility5 := Slot5Ability
}
if(Gui_WeaponCheck5 = 0)
{
WeaponAbility5 =
}
}
if(Slot6AN != "")
{
GuiControl, , Gui_WeaponName6, %Slot6AN%
if(Gui_WeaponCheck6 = 1)
{
WeaponAbility6 := Slot6Ability
}
if(Gui_WeaponCheck6 = 0)
{
WeaponAbility6 =
}
}
if(Slot7AN != "")
{
GuiControl, , Gui_WeaponName7, %Slot7AN%
if(Gui_WeaponCheck7 = 1)
{
WeaponAbility7 := Slot7Ability
}
if(Gui_WeaponCheck7 = 0)
{
WeaponAbility7 =
}
}
if(Slot8AN != "")
{
GuiControl, , Gui_WeaponName8, %Slot8AN%
if(Gui_WeaponCheck8 = 1)
{
WeaponAbility8 := Slot8Ability
}
if(Gui_WeaponCheck8 = 0)
{
WeaponAbility8 =
}
}
if(Slot9AN != "")
{
GuiControl, , Gui_WeaponName9, %Slot9AN%
if(Gui_WeaponCheck9 = 1)
{
WeaponAbility9 := Slot9Ability
}
if(Gui_WeaponCheck9 = 0)
{
WeaponAbility9 =
}
}
if(Slot10AN != "")
{
GuiControl, , Gui_WeaponName10, %Slot10AN%
if(Gui_WeaponCheck10 = 1)
{
WeaponAbility10 := Slot10Ability
}
if(Gui_WeaponCheck10 = 0)
{
WeaponAbility10 =
}
}
if(Slot11AN != "")
{
GuiControl, , Gui_WeaponName11, %Slot11AN%
if(Gui_WeaponCheck11 = 1)
{
WeaponAbility11 := Slot11Ability
}
if(Gui_WeaponCheck11 = 0)
{
WeaponAbility11 =
}
}
if(Slot12AN != "")
{
GuiControl, , Gui_WeaponName12, %Slot12AN%
if(Gui_WeaponCheck12 = 1)
{
WeaponAbility12 := Slot12Ability
}
if(Gui_WeaponCheck12 = 0)
{
WeaponAbility12 =
}
}
if(Slot13AN != "")
{
GuiControl, , Gui_WeaponName13, %Slot13AN%
if(Gui_WeaponCheck13 = 1)
{
WeaponAbility13 := Slot13Ability
}
if(Gui_WeaponCheck13 = 0)
{
WeaponAbility13 =
}
}
if(Slot14AN != "")
{
GuiControl, , Gui_WeaponName14, %Slot14AN%
if(Gui_WeaponCheck14 = 1)
{
WeaponAbility14 := Slot14Ability
}
if(Gui_WeaponCheck14 = 0)
{
WeaponAbility14 =
}
}
if(Slot15AN != "")
{
GuiControl, , Gui_WeaponName15, %Slot15AN%
if(Gui_WeaponCheck15 = 1)
{
WeaponAbility15 := Slot15Ability
}
if(Gui_WeaponCheck15 = 0)
{
WeaponAbility15 =
}
}
if(Slot16AN != "")
{
GuiControl, , Gui_WeaponName16, %Slot16AN%
if(Gui_WeaponCheck16 = 1)
{
WeaponAbility16 := Slot16Ability
}
if(Gui_WeaponCheck16 = 0)
{
WeaponAbility16 =
}
}
if(Slot17AN != "")
{
GuiControl, , Gui_WeaponName17, %Slot17AN%
if(Gui_WeaponCheck17 = 1)
{
WeaponAbility17 := Slot17Ability
}
if(Gui_WeaponCheck17 = 0)
{
WeaponAbility17 =
}
}
if(Slot18AN != "")
{
GuiControl, , Gui_WeaponName18, %Slot18AN%
if(Gui_WeaponCheck18 = 1)
{
WeaponAbility18 := Slot18Ability
}
if(Gui_WeaponCheck18 = 0)
{
WeaponAbility18 =
}
}
if(Slot19AN != "")
{
GuiControl, , Gui_WeaponName19, %Slot19AN%
if(Gui_WeaponCheck19 = 1)
{
WeaponAbility19 := Slot19Ability
}
if(Gui_WeaponCheck19 = 0)
{
WeaponAbility19 =
}
}
if(Slot20AN != "")
{
GuiControl, , Gui_WeaponName20, %Slot20AN%
if(Gui_WeaponCheck20 = 1)
{
WeaponAbility20 := Slot20Ability
}
if(Gui_WeaponCheck20 = 0)
{
WeaponAbility20 =
}
}
Check_SMagicN()
Check_SMagic()
if(Slot3MN != "")
{
GuiControl, , Gui_MagicName3, %Slot3MN%
if(Gui_MagicCheck3 = 1)
{
MagicAbility3 := Slot3Magic
}
if(Gui_MagicCheck3 = 0)
{
MagicAbility3 = 0
}
}
if(Slot4MN != "")
{
GuiControl, , Gui_MagicName4, %Slot4MN%
if(Gui_MagicCheck4 = 1)
{
MagicAbility4 := Slot4Magic
}
if(Gui_MagicCheck4 = 0)
{
MagicAbility4 = 0
}
}
if(Slot5MN != "")
{
GuiControl, , Gui_MagicName5, %Slot5MN%
if(Gui_MagicCheck5 = 1)
{
MagicAbility5 := Slot5Magic
}
if(Gui_MagicCheck5 = 0)
{
MagicAbility5 = 0
}
}
if(Slot6MN != "")
{
GuiControl, , Gui_MagicName6, %Slot6MN%
if(Gui_MagicCheck6 = 1)
{
MagicAbility6 := Slot6Magic
}
if(Gui_MagicCheck6 =0)
{
MagicAbility6 = 0
}
}
if(Slot7MN != "")
{
GuiControl, , Gui_MagicName7, %Slot7MN%
if(Gui_MagicCheck7 = 1)
{
MagicAbility7 := Slot7Magic
}
if(Gui_MagicCheck7 = 0)
{
MagicAbility7 = 0
}
}
if(Slot8MN != "")
{
GuiControl, , Gui_MagicName8, %Slot8MN%
if(Gui_MagicCheck8 = 1)
{
MagicAbility8 := Slot8Magic
}
if(Gui_MagicCheck8 = 0)
{
MagicAbility8 = 0
}
}
}
if((Step >= 19 and Step < 90) or Step >= 1008)
{
if(Gui_CheckUseHPPortal = 1)
{
if(NowHP <= Gui_HPPortal and NowHP != "")
{
if(HuntPlace = 1)
{
MapNumber = 1
MobNumber = 1
MoveWaitCount = 0
SuinAStartX = 364
SuinAEndX = 430
SuinBStartY = 158
SuinBEndY = 227
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
GuiControl, , Gui_NowState, 체력이 %NowHP%가 되어 차원이동 합니다.
CheckPB = 0
Step = 9
return
}
if(HuntPlace = 2)
{
CheckPB = 0
MapNumber = 1
MoveWaitCount = 0
CenterStartY = 150
SuinAStartX = 364
SuinAEndX = 430
SuinBStartY = 158
SuinBEndY = 227
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
GuiControl, , Gui_NowState, 체력이 %NowHP%가 되어 차원이동 합니다.
Step = 1000
return
}
}
}
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000 or WeaponAbility10 = 10000 or WeaponAbility11 = 10000 or WeaponAbility12 = 10000 or WeaponAbility13 = 10000 or WeaponAbility14 = 10000 or WeaponAbility15 = 10000 or WeaponAbility16 = 10000 or WeaponAbility17 = 10000 or WeaponAbility18 = 10000 or WeaponAbility19 = 10000 or WeaponAbility20 = 10000)
{
if(Gui_Grade = 1)
{
CheckPB = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 600
}
}
if(MagicAbility3 = 100 or MagicAbility4 = 100 or MagicAbility5 = 100 or MagicAbility6 = 100 or MagicAbility7 = 100 or MagicAbility8 = 100)
{
if(Gui_Grade = 1)
{
CheckPB = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 650
}
}
if(NowFP < 5)
{
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
CheckPB = 0
MapNumber = 1
MobNumber = 1
MoveWaitCount = 0
CenterStartY = 150
SuinAStartX = 364
SuinAEndX = 430
SuinBStartY = 158
SuinBEndY = 227
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
GuiControl, , Gui_NowState, FP가 부족하여 채우러 갑니다.
Step = 200
return
}
}
if(Step >= 19 and Step < 90)
{
IfNotInString,Location,남쪽 필드
{
OutTime := A_TickCount
ParasTime := OutTime - JoinTime
if(ParasTime < 1200000)
{
ParasCount += 1
}
if(ParasTime >= 1200000)
{
ParasCount = 0
}
if(ParasCount > 4)
{
GuiControl, , Gui_NowState, [포남] 파라스 감지를 감지하여 3분 대기.
ParasCount = 0
Sleep, 180000
}
MapNumber = 1
MobNumber = 1
MoveWaitCount = 0
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 9
return
}
}
if(Step >= 1013 and Step < 1030)
{
IfNotInString,Location,북쪽 필드
{
MapNumber = 1
MobNumber = 1
MoveWaitCount = 0
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 1000
return
}
}
Check_Chat()
if(Chat = 1)
{
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
}
if(Step = 27 or Step = 1026)
{
if(Step = 27)
{
if(Gui_EvadeMand = 1)
{
IfWinNotActive, ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
PixelSearch, MandX, MandY, 0, 0, 775, 460, 0x4A044A, , *fast
if(ErrorLevel = 0)
{
AttackLoopCount = 0
AttackCount = 0
Step = 19
return
}
}
}
if(Gui_HuntAuto = 1)
{
if(HuntPlace = 1)
{
if(Gui_1Muba = 1)
{
if(BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
if(Gui_2Muba = 1)
{
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
if(Gui_3Muba = 1)
{
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility3)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
if(Gui_2ButMuba = 1)
{
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
if(Gui_3ButMuba = 1)
{
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or  BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
if(Gui_4ButMuba = 1)
{
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or  BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility3)
{
HuntPlace = 2
MapNumber = 1
Step = 1000
}
}
}
}
}
}
}
IfWinNotExist,ahk_pid %jPID%
{
if(Step >= 5 and Step < 10000)
{
GuiControl, , Gui_NowState, 오류로 인해 재접속 합니다.
Step = 0
}
}
if(Step = 0)
{
GuiControl, , Gui_NowState, 실행 환경을 초기화 합니다.
SetTimer, incineration, off
CheckPB = 0
WinKill, ahk_pid %jPID%
GroupAdd, ie_gruop, ahk_exe iexplore.exe
WinKill, ahk_exe iexplore.exe
WinKill, ahk_group ie_gruop
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
CountPortal = 0
countsignal = 0
MapNumber = 1
MoveWaitCount = 0
MobNumber = 1
AttackLoopCount = 0
AttackCount = 0
pbtalkcheck = 0
RunDirect = 0
getidc = 1
callid = 1
inciNumber = 1
MLimit := Gui_AllMobLimit/100
MubaStep = 1
CenterStartX = 350
CenterStartY = 150
CenterEndX = 450
CenterEndY = 270
SuinAStartX = 364
SuinAStartY = 182
SuinAEndX = 430
SuinAEndY = 203
SuinBStartX = 388
SuinBStartY = 158
SuinBEndX = 406
SuinBEndY = 227
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
WinKill, ahk_pid %jPID%
GroupAdd, ie_gruop, ahk_exe iexplore.exe
WinKill, ahk_exe iexplore.exe
WinKill, ahk_group ie_gruop
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
FileDelete, Mlog.txt
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Sleep, 5000
Step = 1
}
if(Step = 1)
{
GuiControl, , Gui_NowState, 접속중
pwb := ComObjCreate("InternetExplorer.Application")
Sleep, 3000
pwb.visible:=false
pwb.Navigate("https://nxlogin.nexon.com/common/login.aspx?redirect=https%3a%2f%2fgamebulletin.nexon.com%2felan%2fgame.aspx%3fReturnUrl%3d%252f")
Loading()
LoginURL := pwb.document.URL
if(LoginURL != "https://nxlogin.nexon.com/common/login.aspx?redirect=https%3a%2f%2fgamebulletin.nexon.com%2felan%2fgame.aspx%3fReturnUrl%3d%252f")
{
GuiControl, , Gui_NowState, 로그인 실패(접속불량)
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
LoginMsg := pwb.document.querySelectorAll("[class='saveid']")[0].InnerText
IfNotInString,LoginMsg,로그인 상태 유지
{
GuiControl, , Gui_NowState, 로그인이 되어 있습니다.
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
Sleep, 3000
pwb.document.querySelectorAll("[id='txtNexonID']")[0].Value := NexonID
pwb.document.querySelectorAll("[id='txtPWD']")[0].Value := NexonPassWord
pwb.document.querySelectorAll("[class='button01']")[0].Click()
Loading()
Sleep, 3000
LoginURL := pwb.document.URL
if(LoginURL != "https://gamebulletin.nexon.com/elan/game.aspx?ReturnUrl=%2f")
{
IfInString,LoginURL,errorcode=1
{
GuiControl, , Gui_NowState, 로그인 실패(ID,PW 오입력)
pwb.quit
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
LoginMsg := pwb.document.querySelectorAll("[class='login_wrap']")[0].InnerText
IfInString,LoginMsg,반갑습니다
{
Step = 2
return
}
IfInString,LoginMsg,반갑습니다.
{
GuiControl, , Gui_NowState, 로그인 실패(홈페이지 로딩실패 다시 시작해주세요)
pwb.quit
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Step = 2)
{
Sleep, 3000
GuiControl, , Gui_NowState, 실행중
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
pwb.document.querySelector("[alt='게임시작']").click()
pwb.quit
Step = 3
}
if(Step = 3)
{
Sleep, 5000
ControlGetText, Patch, Static2, Elancia
Sleep, 2000
IfInString,Patch,일랜시아 서버에 연결할 수 없습니다.
{
WinKill, Elancia
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
Step = 5000
return
}
Sleep, 4000
ControlGet, GameStartButton, Visible, , Button1, Elancia
Sleep, 2000
if(GameStartButton = 1)
{
Sleep, 4000
GuiControl, , Gui_NowState, 설정 적용중
WinGet, jPID, PID, Elancia
jelan := new _ClassMemory("ahk_pid " jPID, "", hProcessCopy)
value := jelan.write(0x00460813, 0xE9, "Char", aOffsets*)
value := jelan.write(0x00460814, 0xE8, "Char", aOffsets*)
value := jelan.write(0x00460815, 0xF6, "Char", aOffsets*)
value := jelan.write(0x00460816, 0x12, "Char", aOffsets*)
value := jelan.write(0x00460817, 0x00, "Char", aOffsets*)
value := jelan.write(0x004CFBC5, 0xB2, "Char", aOffsets*)
value := jelan.write(0x004D05CD, 0xB2, "Char", aOffsets*)
value := jelan.write(0x0047C1A9, 0x6A, "Char", aOffsets*)
value := jelan.write(0x0047C1AA, 0x00, "Char", aOffsets*)
value := jelan.write(0x0047C1AB, 0x90, "Char", aOffsets*)
value := jelan.write(0x0047C1AC, 0x90, "Char", aOffsets*)
value := jelan.write(0x0047C1AD, 0x90, "Char", aOffsets*)
value := jelan.write(0x0046035B, 0x90, "Char", aOffsets*)
value := jelan.write(0x0046035C, 0x90, "Char", aOffsets*)
value := jelan.write(0x0046035D, 0x90, "Char", aOffsets*)
value := jelan.write(0x0046035E, 0x90, "Char", aOffsets*)
value := jelan.write(0x0046035F, 0x90, "Char", aOffsets*)
value := jelan.write(0x00460360, 0x90, "Char", aOffsets*)
value := jelan.write(0x0047A18D, 0xEB, "Char", aOffsets*)
value := jelan.write(0x0047AA20, 0xEB, "Char", aOffsets*)
value := jelan.write(0x0047AD18, 0xEB, "Char", aOffsets*)
value := jelan.write(0x0047C17B, 0xE9, "Char", aOffsets*)
value := jelan.write(0x0047C17C, 0x4E, "Char", aOffsets*)
value := jelan.write(0x0047C17D, 0x02, "Char", aOffsets*)
value := jelan.write(0x0047C17E, 0x00, "Char", aOffsets*)
value := jelan.write(0x0047C17F, 0x00, "Char", aOffsets*)
value := jelan.write(0x004A1A7E, 0xE9, "Char", aOffsets*)
value := jelan.write(0x004A1A7F, 0x7D, "Char", aOffsets*)
value := jelan.write(0x004A1A80, 0xE5, "Char", aOffsets*)
value := jelan.write(0x004A1A81, 0x0E, "Char", aOffsets*)
value := jelan.write(0x004A1A82, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590000, 0xE8, "Char", aOffsets*)
value := jelan.write(0x00590001, 0x73, "Char", aOffsets*)
value := jelan.write(0x00590002, 0xD5, "Char", aOffsets*)
value := jelan.write(0x00590003, 0xF7, "Char", aOffsets*)
value := jelan.write(0x00590004, 0xFF, "Char", aOffsets*)
value := jelan.write(0x00590005, 0x60, "Char", aOffsets*)
value := jelan.write(0x00590006, 0xA1, "Char", aOffsets*)
value := jelan.write(0x00590007, 0xE8, "Char", aOffsets*)
value := jelan.write(0x00590008, 0xEA, "Char", aOffsets*)
value := jelan.write(0x00590009, 0x58, "Char", aOffsets*)
value := jelan.write(0x0059000A, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059000B, 0xBB, "Char", aOffsets*)
value := jelan.write(0x0059000C, 0x36, "Char", aOffsets*)
value := jelan.write(0x0059000D, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059000E, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059000F, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590010, 0xB9, "Char", aOffsets*)
value := jelan.write(0x00590011, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590012, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590013, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590014, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590015, 0xBA, "Char", aOffsets*)
value := jelan.write(0x00590016, 0x88, "Char", aOffsets*)
value := jelan.write(0x00590017, 0x05, "Char", aOffsets*)
value := jelan.write(0x00590018, 0x07, "Char", aOffsets*)
value := jelan.write(0x00590019, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059001A, 0xBE, "Char", aOffsets*)
value := jelan.write(0x0059001B, 0x01, "Char", aOffsets*)
value := jelan.write(0x0059001C, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059001D, 0x07, "Char", aOffsets*)
value := jelan.write(0x0059001E, 0x00, "Char", aOffsets*)
value := jelan.write(0x0059001F, 0x8B, "Char", aOffsets*)
value := jelan.write(0x00590020, 0xF8, "Char", aOffsets*)
value := jelan.write(0x00590021, 0xFF, "Char", aOffsets*)
value := jelan.write(0x00590022, 0x15, "Char", aOffsets*)
value := jelan.write(0x00590023, 0xFC, "Char", aOffsets*)
value := jelan.write(0x00590024, 0x83, "Char", aOffsets*)
value := jelan.write(0x00590025, 0x52, "Char", aOffsets*)
value := jelan.write(0x00590026, 0x00, "Char", aOffsets*)
value := jelan.write(0x00590027, 0x50, "Char", aOffsets*)
value := jelan.write(0x00590028, 0x8B, "Char", aOffsets*)
value := jelan.write(0x00590029, 0xC6, "Char", aOffsets*)
value := jelan.write(0x0059002A, 0xC1, "Char", aOffsets*)
value := jelan.write(0x0059002B, 0xE8, "Char", aOffsets*)
value := jelan.write(0x0059002C, 0x1E, "Char", aOffsets*)
value := jelan.write(0x0059002D, 0x25, "Char", aOffsets*)
value := jelan.write(0x0059002E, 0x01, "Char", aOffsets*)
value := jelan.write(0x0059002F, 0xFF, "Char", aOffsets*)
value := jelan.write(0x00590030, 0xFF, "Char", aOffsets*)
value := jelan.write(0x00590031, 0xFF, "Char", aOffsets*)
value := jelan.write(0x00590032, 0x50, "Char", aOffsets*)
value := jelan.write(0x00590033, 0x88, "Char", aOffsets*)
value := jelan.write(0x00590034, 0xD9, "Char", aOffsets*)
value := jelan.write(0x00590035, 0x8B, "Char", aOffsets*)
value := jelan.write(0x00590036, 0xD7, "Char", aOffsets*)
value := jelan.write(0x00590037, 0xE8, "Char", aOffsets*)
value := jelan.write(0x00590038, 0x9F, "Char", aOffsets*)
value := jelan.write(0x00590039, 0xA8, "Char", aOffsets*)
value := jelan.write(0x0059003A, 0xEB, "Char", aOffsets*)
value := jelan.write(0x0059003B, 0xFF, "Char", aOffsets*)
value := jelan.write(0x0059003C, 0x61, "Char", aOffsets*)
value := jelan.write(0x0059003D, 0xC3, "Char", aOffsets*)
value := jelan.write(0x0047B326, 0xE9, "Char", aOffsets*)
value := jelan.write(0x0047B327, 0xD5, "Char", aOffsets*)
value := jelan.write(0x0047B328, 0x40, "Char", aOffsets*)
value := jelan.write(0x0047B329, 0x11, "Char", aOffsets*)
value := jelan.write(0x0047B32A, 0x00, "Char", aOffsets*)
value := jelan.write(0x004C3DC2, 0x03, "Char", aOffsets*)
value := jelan.write(0x0045D98B, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D98C, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D98D, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DA94, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DA95, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DA96, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DAA9, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DAAA, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045DAAB, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D32E, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D32F, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D330, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D4E7, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D4E8, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D4E9, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D43E, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D43F, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D440, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D422, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D423, 0x90, "Char", aOffsets*)
value := jelan.write(0x0045D424, 0x90, "Char", aOffsets*)
value := jelan.write(0x004766E0, 0xB0, "Char", aOffsets*)
value := jelan.write(0x004766E1, 0x01, "Char", aOffsets*)
value := jelan.write(0x004766E2, 0x90, "Char", aOffsets*)
value := jelan.write(0x004766E3, 0x90, "Char", aOffsets*)
value := jelan.write(0x004766E4, 0x90, "Char", aOffsets*)
value := jelan.write(0x004766E5, 0x90, "Char", aOffsets*)
if(Gui_jjOFF = 1)
{
value := jelan.write(0x0047B3EC, 0x4D, "Char", aOffsets*)
}
MIC()
ATKM()
Loop,5
{
ControlSend, , {Enter}, Elancia
}
Step = 4
}
}
if(Step = 4)
{
Sleep, 4000
GuiControl, , Gui_NowState, 서버 선택 중
WinGetTitle, jTitle, ahk_pid %jPID%
if(jTitle = "일랜시아")
{
Server := jelan.read(0x0058DAD0, "UChar", 0xC, 0x8, 0x8, 0x6C)
if(Server = 0)
{
Sleep, 2000
if(Gui_Server = "엘")
{
PostMessage, 0x200, 0, 16187689, , ahk_pid %jPID%
PostMessage, 0x201, 1, 16187689, , ahk_pid %jPID%
PostMessage, 0x202, 0, 16187689, , ahk_pid %jPID%
Sleep, 100
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
}
if(Gui_Server = "테스")
{
PostMessage, 0x200, 0, 17826096, , ahk_pid %jPID%
PostMessage, 0x201, 1, 17826096, , ahk_pid %jPID%
PostMessage, 0x202, 0, 17826096, , ahk_pid %jPID%
Sleep, 100
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
}
Step = 5
}
}
if(jTitle = "Elancia")
{
ControlClick, Button1, ahk_pid %jPID%
Sleep, 100
}
}
if(Step = 5)
{
GuiControl, , Gui_NowState, 캐릭터 선택 중
WinGetTitle, jTitle, ahk_pid %jPID%
if(jTitle = "일랜시아 - 엘" or jTitle = "일랜시아 - 테스")
{
Server := jelan.read(0x0058DAD0, "UChar", 0xC, 0x8, 0x8, 0x6C)
if(Server = 1)
{
Sleep, 2000
if(Gui_CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %jPID%
PostMessage, 0x201, 1, 13107662, , ahk_pid %jPID%
PostMessage, 0x202, 0, 13107662, , ahk_pid %jPID%
}
if(Gui_CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %jPID%
PostMessage, 0x201, 1, 14287311, , ahk_pid %jPID%
PostMessage, 0x202, 0, 14287311, , ahk_pid %jPID%
}
if(Gui_CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %jPID%
PostMessage, 0x201, 1, 15598030, , ahk_pid %jPID%
PostMessage, 0x202, 0, 15598030, , ahk_pid %jPID%
}
if(Gui_CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %jPID%
PostMessage, 0x201, 1, 16908752, , ahk_pid %jPID%
PostMessage, 0x202, 0, 16908752, , ahk_pid %jPID%
}
if(Gui_CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %jPID%
PostMessage, 0x201, 1, 18088402, , ahk_pid %jPID%
PostMessage, 0x202, 0, 18088402, , ahk_pid %jPID%
}
if(Gui_CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %jPID%
PostMessage, 0x201, 1, 19399121, , ahk_pid %jPID%
PostMessage, 0x202, 0, 19399121, , ahk_pid %jPID%
}
if(Gui_CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %jPID%
PostMessage, 0x201, 1, 20513232, , ahk_pid %jPID%
PostMessage, 0x202, 0, 20513232, , ahk_pid %jPID%
}
if(Gui_CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %jPID%
PostMessage, 0x201, 1, 21889488, , ahk_pid %jPID%
PostMessage, 0x202, 0, 21889488, , ahk_pid %jPID%
}
if(Gui_CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %jPID%
PostMessage, 0x201, 1, 23200209, , ahk_pid %jPID%
PostMessage, 0x202, 0, 23200209, , ahk_pid %jPID%
}
if(Gui_CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %jPID%
PostMessage, 0x201, 1, 24314321, , ahk_pid %jPID%
PostMessage, 0x202, 0, 24314321, , ahk_pid %jPID%
}
Sleep, 100
PostMessage, 0x200, 0, 22086223, , ahk_pid %jPID%
PostMessage, 0x201, 1, 22086223, , ahk_pid %jPID%
PostMessage, 0x202, 0, 22086223, , ahk_pid %jPID%
Sleep, 3000
if(Gui_relogerror = 1)
{
Sleep, 7000
}
Step = 6
}
}
}
if(Step = 6)
{
GuiControl, , Gui_NowState, 캐릭터 접속 대기 중
Server := jelan.read(0x0058DAD0, "UChar", 0xC, 0x10, 0x8, 0x36C)
if(Server = 1)
{
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
GuiControl, , Gui_NowState, 접속 오류로 대기 후 재시작 합니다.
Sleep, 300000
Step = 0
return
}
WinGetTitle, jTitle, ahk_pid %jPID%
if(jTitle != "일랜시아" and jTitle != "일랜시아 - 엘" and jTitle != "일랜시아 - 테스")
{
GuiControl, , Gui_NowState, 접속 완료
GuiControl, , Gui_CharName, %jTitle%
Sleep, 100
WinMove, ahk_pid %jPID%, , 0, 0
Sleep, 100
WinMove, ahk_id %Gui_ID%, , 327, 135
Sleep, 100
Step = 7
}
}
if(Step = 7)
{
GuiControl, , Gui_NowState, 캐릭터 초기 설정 중
if(Gui_jjOn = 1)
{
SetTimer, incineration, 950
}
WPdisablescript()
incineratescript()
Run, *RunAs MRMSPH.exe
WinWait, ahk_exe MRMSPH.exe, , 15
;Run, *RunAs helan.exe
;WinWait, ahk_exe helan.exe, , 15
Sleep, 2000
WinHide, MRMSPH
SetFormat, integer, h
AbilityADD := jelan.processPatternScan(, 0x7FFFFFFF, 0xB0, 0x62, 0x53, 0x00, 0x01, 0x03, 0x00)
AbilityNameADD := AbilityADD + 0x64
AbilityValueADD := AbilityADD + 0x264
SetFormat, integer, d
Sleep, 100
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(Gui_2ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue2 := ReadAbility(Gui_Weapon1)
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(Gui_3ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(Gui_4ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
BWValue3 := ReadAbility(Gui_Weapon3)
}
IfWinNotActive, ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
if(FirstCheck = 1)
{
if(Regloady = 0)
{
Get_HP()
CheckFirstHP := MaxHP
ProgramStartTime := A_TickCount
}
if(Regloady = 1)
{
CheckFirstHP := RCFH
ProgramStartTime := RPST
}
FirstCheck = 0
}
Send, !m
Sleep, 1000
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, flshdk{Space}apsb{Space}{Tab}zldk{Space}apsb{Tab}znzl{Space}apsb{Tab}zmfhfltm{Space}apsb{Tab}flshtm{Space}apsb{Tab}emrhf{Space}apsb{Tab}wlrdjq{Tab}rlfdlfgdmstntoreo{Space}apsb{Enter}
Sleep, 1000
Check_Inven()
if(Inven = 1)
{
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
Move_Inven()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
}
if(Inven = 0)
{
Move_Inven()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 73, 1507329, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
}
PostMessage, 0x100, 56, 589825, , ahk_pid %jPID%
if(Mount = 0)
{
PostMessage, 0x100, 56, 589825, , ahk_pid %jPID%
PostMessage, 0x101, 56, 589825, , ahk_pid %jPID%
Sleep, 100
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
Step = 8
}
if(Step = 8)
{
GuiControl, , Gui_NowState, 체작장소 설정 중
if(Gui_CheckUseMagic = 1)
{
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
value := jelan.write(0x00527A4C, 3, "UInt")
Stack_MN()
CritHP := Gui_CHP
Crit_HM()
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
if(Gui_HuntAuto = 1)
{
if(Gui_1Muba = 1)
{
BWValue1 := ReadAbility(Gui_Weapon1)
if(BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 1000
}
if(BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 9
}
}
if(Gui_2Muba = 1)
{
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 1000
}
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 9
}
}
if(Gui_3Muba = 1)
{
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
BWValue3 := ReadAbility(Gui_Weapon3)
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility3)
{
HuntPlace = 2
Step = 1000
}
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2 and BWValue3 < Gui_LimitAbility3)
{
HuntPlace = 1
Step = 9
}
}
if(Gui_2ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
BWValue1 := ReadAbility(Gui_Weapon1)
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 1000
}
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 9
}
}
if(Gui_3ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or  BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 1000
}
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 9
}
}
if(Gui_4ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
BWValue3 := ReadAbility(Gui_Weapon3)
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or  BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility3)
{
HuntPlace = 2
Step = 1000
}
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2 and BWValue3 < Gui_LimitAbility3)
{
HuntPlace = 1
Step = 9
}
}
}
if(Gui_HuntPonam = 1)
{
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(Gui_2ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(Gui_3ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(Gui_4ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
BWValue3 := ReadAbility(Gui_Weapon3)
}
HuntPlace = 1
Step = 9
}
if(Gui_HuntPobuk = 1)
{
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(Gui_2ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(Gui_3ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(Gui_4ButMuba = 1)
{
BWValue0 := ReadAbility("격투")
}
BWValue1 := ReadAbility(Gui_Weapon1)
BWValue2 := ReadAbility(Gui_Weapon2)
BWValue3 := ReadAbility(Gui_Weapon3)
}
HuntPlace = 2
Step = 1000
}
}
if(Step = 9)
{
GuiControl, , Gui_NowState, [포남] 라깃 사용 중
value := jelan.write(0x0045D28F, 0xE9, "Char", aOffsets*)
value := jelan.write(0x0045D290, 0x8A, "Char", aOffsets*)
value := jelan.write(0x0045D291, 0x0A, "Char", aOffsets*)
value := jelan.write(0x0045D292, 0x00, "Char", aOffsets*)
value := jelan.write(0x0045D293, 0x00, "Char", aOffsets*)
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
if(FirstPortal = 1)
{
if(Gui_CheckUseParty = 1)
{
Random, CountPortal, 1, 2
}
if(Gui_CheckUseParty = 0)
{
Random, CountPortal, 0, 2
}
FirstPortal = 1
}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal += 1
Step = 10
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal += 1
Step = 10
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal = 0
Step = 10
return
}
}
}
if(Step = 10)
{
GuiControl, , Gui_NowState, [포남] 차원이동 검사 중
if(Gui_CheckUseMagic = 1)
{
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Step = 11
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
IfInString,Location,[베타차원] 포프레스네 마을
{
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Step = 11
}
if(Gui_CheckUseParty = 1)
{
CountPortal = 1
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
IfInString,Location,[감마차원] 포프레스네 마을
{
getNpcidFromFile()
Step = 11
}
}
if(Step = 11)
{
Mapnumber = 1
GuiControl, , Gui_NowState, [포남] 빛나는가루 소각 중
if(Gui_jjON = 1)
{
Loop,50
{
SetFormat, integer, H
invenslot += 4
itemm := jelan.readString(0x0058DAD4, 50, "UTF-16", 0x178, 0xBE, 0x8, invenslot, 0x8, 0x8, 0x0)
SetFormat, integer, D
IfInString,itemm,빛나는가루
{
itemnum += 1
}
}
if(itemnum > 2)
{
inciloop := itemnum - 2
loop,%inciloop%
{
value := jelan.writeString(0x005909C0, "빛나는가루" , "UTF-16")
incinerate()
Sleep, 1000
}
}
itemnum =
invenslot =
}
GuiControl, , Gui_NowState, [포남] 라깃 갯수 체크 중
if(Gui_CheckUseMagic = 1)
{
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
}
Get_MsgM()
Get_Perfect()
RasCount := Gui_RasCount
if(RasCount <= 5)
{
Step = 100
}
if(RasCount > 5)
{
Step = 12
}
}
if(Step = 12)
{
GuiControl, , Gui_NowState, [포남] 파티 설정 중
Check_State()
if(State = 1)
{
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
}
if(Gui_PartyOff = 1)
{
Move_StateForMount()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
PostDClick(190,310)
Sleep, 100
PostDClick(225,310)
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
}
Move_State()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 500
Check_State()
Check_StatePos()
if(StatePosX = 565 and StatePosY = 655 and State = 1)
{
if(Gui_CheckUseParty = 1)
{
Step = 900
}
if(Gui_CheckUseParty = 0)
{
Step = 13
}
}
}
if(Step = 13)
{
if(Gui_CheckUseParty = 1)
{
party()
}
if(Gui_KON = 1)
{
GuiControl, , Gui_NowState, [포남] 리노아와 대화준비중
Sleep, 1000
}
if(Gui_KON = 0)
{
GuiControl, , Gui_NowState, [포남] 포남으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(440,476)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
}
if(BWValue0 = 9999)
{
BWValue0 := ReadAbility("격투")
SetFormat, Float, 0.2
TempAbility := BWValue0 / 100
GuiControl, , Gui_BasicWValue0, %TempAbility%
SetFormat, Float, 0
}
if(BWValue1 = 9999)
{
BWValue1 := ReadAbility(Gui_Weapon1)
SetFormat, Float, 0.2
TempAbility := BWValue1 / 100
GuiControl, , Gui_BasicWValue1, %TempAbility%
SetFormat, Float, 0
}
if(BWValue2 = 9999)
{
BWValue2 := ReadAbility(Gui_Weapon2)
SetFormat, Float, 0.2
TempAbility := BWValue2 / 100
GuiControl, , Gui_BasicWValue2, %TempAbility%
SetFormat, Float, 0
}
if(BWValue3 = 9999)
{
BWValue3 := ReadAbility(Gui_Weapon3)
SetFormat, Float, 0.2
TempAbility := BWValue3 / 100
GuiControl, , Gui_BasicWValue3, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility1 = 9999)
{
WeaponAbility1 := Slot1Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility1 / 100
GuiControl, , Gui_WeaponValue1, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility2 = 9999)
{
WeaponAbility2 := Slot2Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility2 / 100
GuiControl, , Gui_WeaponValue2, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility3 = 9999)
{
WeaponAbility3 := Slot3Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility3 / 100
GuiControl, , Gui_WeaponValue3, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility4 = 9999)
{
WeaponAbility4 := Slot4Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility4 / 100
GuiControl, , Gui_WeaponValue4, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility5 = 9999)
{
WeaponAbility5 := Slot5Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility5 / 100
GuiControl, , Gui_WeaponValue5, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility6 = 9999)
{
WeaponAbility6 := Slot6Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility6 / 100
GuiControl, , Gui_WeaponValue6, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility7 = 9999)
{
WeaponAbility7 := Slot7Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility7 / 100
GuiControl, , Gui_WeaponValue7, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility8 = 9999)
{
WeaponAbility8 := Slot8Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility8 / 100
GuiControl, , Gui_WeaponValue8, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility9 = 9999)
{
WeaponAbility9 := Slot9Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility9 / 100
GuiControl, , Gui_WeaponValue9, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility10 = 9999)
{
WeaponAbility10 := Slot10Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility10 / 100
GuiControl, , Gui_WeaponValue10, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility11 = 9999)
{
WeaponAbility11 := Slot11Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility11 / 100
GuiControl, , Gui_WeaponValue11, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility12 = 9999)
{
WeaponAbility12 := Slot12Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility12 / 100
GuiControl, , Gui_WeaponValue12, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility13 = 9999)
{
WeaponAbility13 := Slot13Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility13 / 100
GuiControl, , Gui_WeaponValue13, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility14 = 9999)
{
WeaponAbility14 := Slot14Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility14 / 100
GuiControl, , Gui_WeaponValue14, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility15 = 9999)
{
WeaponAbility15 := Slot15Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility15 / 100
GuiControl, , Gui_WeaponValue15, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility16 = 9999)
{
WeaponAbility16 := Slot16Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility16 / 100
GuiControl, , Gui_WeaponValue16, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility17 = 9999)
{
WeaponAbility17 := Slot17Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility17 / 100
GuiControl, , Gui_WeaponValue17, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility18 = 9999)
{
WeaponAbility18 := Slot18Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility18 / 100
GuiControl, , Gui_WeaponValue18, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility19 = 9999)
{
WeaponAbility19 := Slot19Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility19 / 100
GuiControl, , Gui_WeaponValue19, %TempAbility%
SetFormat, Float, 0
}
if(WeaponAbility20 = 9999)
{
WeaponAbility20 := Slot20Ability
SetFormat, Float, 0.2
TempAbility := WeaponAbility20 / 100
GuiControl, , Gui_WeaponValue20, %TempAbility%
SetFormat, Float, 0
}
if(MagicAbility3 = 99)
{
MagicAbility3 := Slot3Magic
TempAbility := MagicAbility3
GuiControl, , Gui_MagicValue3, %TempAbility%
}
if(MagicAbility4 = 99)
{
MagicAbility4 := Slot4Magic
TempAbility := MagicAbility4
GuiControl, , Gui_MagicValue4, %TempAbility%
}
if(MagicAbility5 = 99)
{
MagicAbility5 := Slot5Magic
TempAbility := MagicAbility5
GuiControl, , Gui_MagicValue5, %TempAbility%
}
if(MagicAbility6 = 99)
{
MagicAbility6 := Slot6Magic
TempAbility := MagicAbility6
GuiControl, , Gui_MagicValue6, %TempAbility%
}
if(MagicAbility7 = 99)
{
MagicAbility7 := Slot7Magic
TempAbility := MagicAbility7
GuiControl, , Gui_MagicValue7, %TempAbility%
}
if(MagicAbility8 = 99)
{
MagicAbility8 := Slot8Magic
TempAbility := MagicAbility8
GuiControl, , Gui_MagicValue8, %TempAbility%
}
Step = 14
}
if(Step = 14)
{
GuiControl, , Gui_NowState, [포남] 움직임 체크 중
if(Gui_KON = 1)
{
Sleep, 300
}
if(Gui_KON = 0)
{
Check_Moving()
if(Moving = 0)
{
Sleep, 300
Check_Moving()
if(Moving = 0)
{
AltR()
Sleep, 300
}
}
}
Step = 15
}
if(Step = 15)
{
GuiControl, , Gui_NowState, [포남] 캐릭터 위치 체크 중
Get_Pos()
if(Gui_KON = 1)
{
if(PosY > 180)
{
Step = 9
}
if(PosX >= 32 and PosX <= 174 and PosY >= 15 and PosY <= 180)
{
Step = 16
}
else
{
Step = 13
}
}
if(Gui_KON = 0)
{
if(PosY > 180)
{
Step = 9
}
if(PosX >= 109 and PosX <= 134 and PosY >= 178 and PosY <= 180)
{
Step = 16
}
else
{
Step = 13
}
}
}
if(Step = 16)
{
GuiControl, , Gui_NowState, [포남] 갈리드 체크 중
Get_Gold()
if(Gold < 100000)
{
Step = 500
}
else
{
Step = 17
}
}
if(Step = 17)
{
Get_Location()
GuiControl, , Gui_NowState, [포남] NPC 대화 중
Move_NPCTalkForm()
callid = 1
if(Gui_KON = 1)
{
IfInString,Location,알파
{
value := jelan.write(0x00527B1C, AAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, AAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, AAI, "UInt")
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
}
IfInString,Location,베타
{
value := jelan.write(0x00527B1C, BAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, BAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, BAI, "UInt")
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
}
IfInString,Location,감마
{
value := jelan.write(0x00527B1C, GAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, GAI, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, GAI, "UInt")
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
}
}
if(Gui_KON = 0)
{
Sleep, 200
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 800
}
if(Gui_KON = 1)
{
if(ipmak >5)
{
MsgBox, , 리노아 호출오류, 감응OFF, 3
GuiControl, , Gui_KOFF, 1
}
}
NPCTalkedTime := A_TickCount
if(RCC >= 1)
{
Step = 90
}
if(RCC = 0)
{
Step = 18
}
}
if(Step = 18)
{
GuiControl, , Gui_NowState, [포남] 포남 입장 중
if(Gui_KON = 1)
{
IfInString,Location,[알파차원]
{
value := jelan.write(0x00527B1C, AAD, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, AAD, "UInt")
Sleep, 50
}
IfInString,Location,[베타차원]
{
value := jelan.write(0x00527B1C, BAD, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, BAD, "UInt")
Sleep, 50
}
IfInString,Location,[감마차원]
{
value := jelan.write(0x00527B1C, GAD, "UInt")
Sleep, 50
value := jelan.write(0x00527B1C, GAD, "UInt")
Sleep, 50
}
}
NPCTalkTime := A_TickCount - NPCTalkedTime
if(NPCTalkTime >= 5000)
{
AltR()
Sleep, 1000
ipmak += 1
FileAppend, %FormNumber%`,%NPCMsg%`n, Mlog.txt
Step = 13
return
}
Check_FormNumber()
Check_NPCMsg()
Sleep, 400
PostClick(395,325)
Sleep, 400
if(FormNumber = 97)
{
IfInString,NPCMsg,100
{
GuiControl, , Gui_NowState, [포남] 97
Entrance = 0
Sleep, 400
PostClick(90,80)
Sleep, 400
GuiControl, , Gui_NowState, [포남] 81
Entrance = 0
PostMessage, 0x100, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 54, 458753, , ahk_pid %jPID%
JoinTime := A_TickCount
Sleep, 400
if(Gui_jjOn = 1)
{
Send, {F15 Down}
Sleep, 40
Send, {F15 Up}
Sleep, 10
Send, {F15 Down}
Sleep, 40
Send, {F15 Up}
PickUp_itemsetPS()
}
Step = 19
if(Gui_KON = 1)
{
Sleep, 500
Get_Location()
IfInString,Location,남쪽
{
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
}
}
}
}
}
if(Step = 19)
{
GuiControl, , Gui_NowState, [포남] 맵 이동 중
ipmak = 0
FileDelete, Mlog.txt
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
if(Gui_MoveLoute1 = 1 or Gui_MoveLoute2 = 1 or Gui_MoveLoute3 = 1 or Gui_MoveLoute4 = 1)
{
if(MapNumber >= 295)
{
OpenMap()
MapNumber = 1
Step = 9
return
}
CharMovePonam(Gui_MoveLoute1,Gui_MoveLoute2,Gui_MoveLoute3,Gui_MoveLoute4)
}
OpenMap()
PostMove(485,577)
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}

Get_Location()
npcidResult := getNpcidFromFile()

msgbox, npcidResult%npcidResult%

if(npcidResult = true)
{
    Step = 20
}
else{
    Step = 7777
}
}

if(Step = 7777){

GuiControl, , Gui_NowState, [포남] NPCID 수동으로 받는중
   getServer()
  
    sleep, 1000

    msgbox, 서버%npcServer%
    
    ;동파
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(520, 178)
Check_Map()
Check_Map()
    Sleep, 15000
    KeyClick("CTRL9")
    Sleep, 1000
    Check_OID()
    
    category = 동파
    setNpcidToFile(npcServer, category ,CCD)    
    sleep, 2500

    msgbox, %npcServer%%category% %CCD%

    ;서파
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(207, 450)
Check_Map()
Check_Map()
    Sleep, 30000
    KeyClick("CTRL0")
    Sleep, 1000
    Check_OID()
    category = 서파
    setNpcidToFile(npcServer, category ,CCD)    
    sleep, 2500

    msgbox, %npcServer% %category% %CCD%
    

step := 20
}

if(Step = 20)
{
;MsgBox,   "step20call"
GuiControl, , Gui_NowState, [포남] 움직임 체크 중
Check_Moving()
Get_Pos()
Get_MovePos()
if(Moving = 0)
{
Sleep, 200
Check_Moving()
if(Moving = 0)
{
Step = 21
}
}
if((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2))
{
MoveWaitCount = 0
Step = 24
}
}
if(Step = 21)
{
Get_Pos()
Get_MovePos()
if((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2))
{
MoveWaitCount = 0
Step = 24
}
if(!((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2)))
{
if(MoveWaitCount >= 2)
{
MoveWaitCount = 0
Step = 9
}
else
{
Step = 24
}
}
}
if(Step = 24)
{
GuiControl, , Gui_NowState, [포남] 몹 찾는 중
IfWinNotActive, ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
if(Gui_Ent = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
}
if(Gui_Rockey = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
}
if(Gui_EntRockey = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
}
}
if(Gui_Mand = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
if(Gui_AllMobAND = 1)
{
if(Gui_1Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit or BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit and BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit or BWValue2 < Gui_AllMobLimit or BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit and BWValue2 >= Gui_AllMobLimit and BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit or BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit and BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit or BWValue1 < Gui_AllMobLimit or BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit and BWValue1 >= Gui_AllMobLimit and BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_4ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit or BWValue1 < Gui_AllMobLimit or BWValue2 < Gui_AllMobLimit or BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit and BWValue1 >= Gui_AllMobLimit and BWValue2 >= Gui_AllMobLimit and BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(Gui_AllMobOR = 1)
{
if(Gui_1Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3Muba = 1)
{
if(BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit and BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit or BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_4ButMuba = 1)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit and BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit or BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(Gui_MobMagic = 1)
{
if(Gui_1Muba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2Muba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3Muba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit and BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit or BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_2ButMuba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_3ButMuba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(Gui_4ButMuba = 1)
{
if(MagicAbility3 < MLimit and MagicAbility4 < MLimit and MagicAbility5 < MLimit and MagicAbility6 < MLimit and MagicAbility7 < MLimit and MagicAbility8 < MLimit)
{
if(BWValue0 < Gui_AllMobLimit and BWValue1 < Gui_AllMobLimit and BWValue2 < Gui_AllMobLimit and BWValue3 < Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xFFB68C, 10, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 760, 450, 0xE7E7E7, 5, *fast
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(BWValue0 >= Gui_AllMobLimit or BWValue1 >= Gui_AllMobLimit or BWValue2 >= Gui_AllMobLimit or BWValue3 >= Gui_AllMobLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
if(MagicAbility3 >= MLimit or MagicAbility4 >= MLimit or MagicAbility5 >= MLimit or MagicAbility6 >= MLimit or MagicAbility7 >= MLimit or MagicAbility8 >= MLimit)
{
PixelSearch, MobX, MobY, 0, 0, 775, 460, 0x4A044A, 10, *fast
}
}
}
if(ErrorLevel = 0)
{
PostClick(MobX,MobY)
Gosub, 감흥
PostMove(470,575)
WinGetPos, ElanciaClientX, ElanciaClientY, Width, Height, ahk_pid %jPID%
SplashX := MobX + ElanciaClientX - 30
SplashY := MobY + ElanciaClientY - 20
SplashImage, %MobNumber%:, b X%SplashX% Y%SplashY% W80 H80 CW000000
MobNumber += 1
if(MobNumber >= 11)
{
MobNumber = 1
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 19
return
}
AttackLoopCount = 0
AttackCount = 0
Sleep, 500
Step = 25
return
}
if(ErrorLevel = 1)
{
MobNumber = 1
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 19
return
}
}
if(Step = 25)
{
GuiControl, , Gui_NowState, [포남] 몹 공격 체크 중
AttackLoopCount += 1
Check_Attack()
if(Attack = 0)
{
AttackCount += 1
}
if(Attack = 1 or Attack = 2)
{
AttackCount = 0
}
if(AttackLoopCount >= 10)
{
if(AttackCount > 5)
{
AttackLoopCount = 0
AttackCount = 0
Step = 24
}
else
{
MobNumber = 1
AttackLoopCount = 0
AttackCount = 0
movmob := A_TickCount
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 26
}
}
}
if(Step = 26)
{
GuiControl, , Gui_NowState, [포남] 몹 근접 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 200
Check_Moving()
if(Moving = 0)
{
AltR()
Step = 27
}
}
movmob2 := A_TickCount - movmob
if(movmob2 >= 2300)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 24
}
}
if(Step = 27)
{
GuiControl, , Gui_NowState, [포남] 무바 중
if(Gui_1Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(RepairWeaponCount1 >= 5)
{
RepairWeaponCount1 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 240
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 240
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
}
if(Gui_2Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 = 0
}
MubaStep = 1
return
}
}
if(Gui_3Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5 or RepairWeaponCount3 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
RepairWeaponCount3 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 = 0
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount3 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount3 = 0
}
MubaStep = 1
return
}
}
if(Gui_2ButMuba = 1)
{
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(RepairWeaponCount1 >= 5)
{
RepairWeaponCount1 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
if(Gui_3ButMuba = 1)
{
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount2 += 1
}
if(Weapon != 0)
{
RepairWeaponCount2 = 0
}
MubaStep = 4
return
}
if(MubaStep = 4)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
if(Gui_4ButMuba = 1)
{
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5 or RepairWeaponCount3 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
RepairWeaponCount3 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount2 += 1
}
if(Weapon != 0)
{
RepairWeaponCount2 = 0
}
MubaStep = 4
return
}
if(MubaStep = 4)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 5
return
}
if(MubaStep = 5)
{
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount3 += 1
}
if(Weapon != 0)
{
RepairWeaponCount3 = 0
}
MubaStep = 6
return
}
if(MubaStep = 6)
{
WPD()
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
Sleep, 100
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
}
if(Step = 90)
{
GuiControl, , Gui_NowState, [포남] 포남링/생결 교환 중
NPCTalkTime := A_TickCount - NPCTalkedTime
if(NPCTalkTime >= 5000)
{
AltR()
Sleep, 1000
ipmak += 1
FileAppend, %FormNumber%1`,%NPCMsg%`n, Mlog.txt
Step = 13
return
}
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 85)
{
Sleep, 400
PostClick(375,340)
Sleep, 600
Step = 91
}
}
if(Step = 91)
{
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 121)
{
Sleep, 400
PostClick(115,65)
Sleep, 800
Step = 93
}
}
if(Step = 93)
{
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 85)
{
IfInString,NPCMsg,도전
{
Sleep, 400
PostClick(123,85)
Sleep, 800
step = 94
}
}
}
if(Step = 94)
{
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 121)
{
Sleep, 400
PostClick(120,80)
Sleep, 800
Step = 95
}
}
if(Step = 95)
{
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 85)
{
IfInString,NPCMsg,확률
{
Sleep, 400
PostClick(123,85)
Sleep, 800
step = 96
}
}
}
if(Step = 96)
{
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 121)
{
Sleep, 400
PostClick(80,115)
Sleep, 800
RCC = 0
Step = 13
}
}
if(Step = 100)
{
GuiControl, , Gui_NowState, [라깃구매] 잡화점으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(345,297)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 101
}
if(Step = 101)
{
GuiControl, , Gui_NowState, [라깃구매] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 102
}
}
}
if(Step = 102)
{
GuiControl, , Gui_NowState, [라깃구매] 지역 체크 중
Get_Location()
IfInString,Location,잡화점
{
Step = 103
}
IfNotInString,Location,잡화점
{
AltR()
Step = 100
}
}
if(Step = 103)
{
GuiControl, , Gui_NowState, [라깃구매] 갈리드 체크 중
Get_Gold()
if(Gold <= 100000)
{
Step = 500
}
else
{
Step = 104
}
}
if(Step = 104)
{
GuiControl, , Gui_NowState, [라깃구매] NPC 대화 중
Move_Buy()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 52, 327681, , ahk_pid %jPID%
PostMessage, 0x101, 52, 327681, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
ShopOpendTime := A_TickCount
Sleep, 500
Step = 105
}
if(Step = 105)
{
GuiControl, , Gui_NowState, [라깃구매] NPC 메뉴 체크 중
Check_NPCMenu()
if(NPCMenu = 1)
{
Check_NPCMenuPos()
if(NPCMenuBuyPosX != "" and NPCMenuBuyPosY != "")
{
Sleep, 500
PostClick(NPCMenuBuyPosX,NPCMenuBuyPosY)
BuyCheckedTime := A_TickCount
Step = 106
}
}
if(NPCMenu = 0)
{
ShopOpenTime := A_TickCount - ShopOpendTime
if(ShopOpenTime >= 10000)
{
Step = 104
}
}
}
if(Step = 106)
{
GuiControl, , Gui_NowState, [라깃구매] 구매창 체크 중
Check_Shop()
if(Buy = 1)
{
Sleep, 500
Step = 107
}
if(Buy = 0)
{
BuyCheckTime := A_TickCount - BuyCheckedTime
if(BuyCheckTime >= 10000)
{
Step = 104
}
}
}
if(Step = 107)
{
GuiControl, , Gui_NowState, [라깃구매] 라깃 구매 중
PostClick(180,60)
Sleep, 100
Loop,11
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
}
PostMessage, 0x100, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x101, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x100, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x101, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
RasCount := Gui_RasCount+55
GuiControl, , Gui_RasCount, %RasCount%
Sleep, 2000
Step = 108
}
if(Step = 108)
{
GuiControl, , Gui_NowState, [라깃구매] 구매창 닫는 중
Check_Shop()
if(Buy = 1)
{
Sleep, 1000
PostMessage, 0x100, 27, 65537, , ahk_pid %jPID%
PostMessage, 0x101, 27, 65537, , ahk_pid %jPID%
Sleep, 1000
Step = 109
}
}
if(Step = 109)
{
GuiControl, , Gui_NowState, [라깃구매] 구매창 닫힘 체크 중
Check_Shop()
if(Buy = 0)
{
Step = 110
}
if(Buy = 1)
{
Step = 108
}
}
if(Step = 110)
{
GuiControl, , Gui_NowState, [라깃구매] 잡화점 밖으로 이동 중
Loop,3
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
Sleep, 500
}
Step = 111
}
if(Step = 111)
{
GuiControl, , Gui_NowState, [라깃구매] 지역 체크 중
Get_Location()
IfInString,Location,잡화점
{
AltR()
Step = 109
}
IfNotInString,Location,잡화점
{
Step = 112
}
}
if(Step = 112)
{
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(370,310)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Sleep, 500
Step = 113
}
if(Step = 113)
{
if(HuntPlace = 1)
{
Step = 11
}
if(HuntPlace = 2)
{
Step = 1002
}
}
if(Step = 200)
{
GuiControl, , Gui_NowState, [FP채우기] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 201
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 201
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 201
return
}
}
}
if(Step = 201)
{
GuiControl, , Gui_NowState, [FP채우기] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 202
}
IfInString,Location,[베타차원] 포프레스네 마을
{
Step = 202
}
IfInString,Location,[감마차원] 포프레스네 마을
{
Step = 202
}
}
if(Step = 202)
{
GuiControl, , Gui_NowState, [FP채우기] 베이커리로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(295,262)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 203
}
if(Step = 203)
{
GuiControl, , Gui_NowState, [FP채우기] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 204
}
}
}
if(Step = 204)
{
GuiControl, , Gui_NowState, [FP채우기] 지역 체크 중
Get_Location()
IfInString,Location,베이커리
{
Step = 205
}
IfNotInString,Location,베이커리
{
AltR()
Step = 202
}
}
if(Step = 205)
{
GuiControl, , Gui_NowState, [FP채우기] 갈리드 체크 중
Get_Gold()
if(Gold <= 100000)
{
Step = 500
}
else
{
Step = 206
}
}
if(Step = 206)
{
GuiControl, , Gui_NowState, [FP채우기] NPC 대화 중
Move_Buy()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
ShopOpendTime := A_TickCount
Step = 207
}
if(Step = 207)
{
GuiControl, , Gui_NowState, [FP채우기] NPC 메뉴 체크 중
Check_NPCMenu()
if(NPCMenu = 1)
{
Check_NPCMenuPos()
if(NPCMenuBuyPosX != "" and NPCMenuBuyPosY != "")
{
Sleep, 700
PostClick(NPCMenuBuyPosX,NPCMenuBuyPosY)
BuyCheckedTime := A_TickCount
Step = 208
}
}
if(NPCMenu = 0)
{
ShopOpenTime := A_TickCount - ShopOpendTime
if(ShopOpenTime >= 10000)
{
Step = 206
}
}
}
if(Step = 208)
{
GuiControl, , Gui_NowState, [FP채우기] 구매창 체크 중
Check_Shop()
if(Buy = 1)
{
Sleep, 500
Step = 209
}
if(Buy = 0)
{
BuyCheckTime := A_TickCount - BuyCheckedTime
if(BuyCheckTime >= 10000)
{
Step = 206
}
}
}
if(Step = 209)
{
GuiControl, , Gui_NowState, [FP채우기] 식빵 구매 중
PostClick(180,60)
Sleep, 100
Loop,27
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
}
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
Sleep, 1000
Step = 210
}
if(Step = 210)
{
GuiControl, , Gui_NowState, [FP채우기] 구매창 닫는 중
Check_Shop()
if(Buy = 1)
{
Sleep, 300
PostMessage, 0x100, 27, 65537, , ahk_pid %jPID%
PostMessage, 0x101, 27, 65537, , ahk_pid %jPID%
Sleep, 300
Step = 211
}
}
if(Step = 211)
{
GuiControl, , Gui_NowState, [FP채우기] 구매창 닫힘 체크 중
Check_Shop()
if(Buy = 0)
{
Step = 212
}
if(Buy = 1)
{
Step = 210
}
}
if(Step = 212)
{
GuiControl, , Gui_NowState, [FP채우기] 식빵 먹는 중
Check_Shop()
if(Buy = 0)
{
Loop,3
{
Loop,50
{
PostMessage, 0x100, 57, 655361, , ahk_pid %jPID%
PostMessage, 0x101, 57, 655361, , ahk_pid %jPID%
}
Sleep, 500
}
Sleep, 100
Step = 213
}
}
if(Step = 213)
{
GuiControl, , Gui_NowState, [FP채우기] FP 체크 중
Get_FP()
if(NowFP != MaxFP)
{
Sleep, 100
Step = 205
}
if(NowFP = MaxFP)
{
Sleep, 100
Step = 214
}
}
if(Step = 214)
{
GuiControl, , Gui_NowState, [FP채우기] 베이커리 밖으로 이동 중
Loop,3
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
Sleep, 500
}
Step = 215
}
if(Step = 215)
{
GuiControl, , Gui_NowState, [FP채우기] 지역 체크 중
Get_Location()
IfInString,Location,베이커리
{
AltR()
Step = 214
}
IfNotInString,Location,베이커리
{
if(HuntPlace = 1)
{
Step = 11
}
if(HuntPlace = 2)
{
Step = 1002
}
}
}
if(Step = 300)
{
GuiControl, , Gui_NowState, [무기수리] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 301
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 301
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 301
return
}
}
}
if(Step = 301)
{
GuiControl, , Gui_NowState, [무기수리] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 302
}
IfInString,Location,[베타차원] 포프레스네 마을
{
Step = 302
}
IfInString,Location,[감마차원] 포프레스네 마을
{
Step = 302
}
}
if(Step = 302)
{
GuiControl, , Gui_NowState, [무기수리] 무기상점으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(348,206)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 303
}
if(Step = 303)
{
GuiControl, , Gui_NowState, [무기수리] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 304
}
}
}
if(Step = 304)
{
GuiControl, , Gui_NowState, [무기수리] 지역 체크 중
Get_Location()
IfInString,Location,석공소
{
Step = 305
}
IfNotInString,Location,석공소
{
AltR()
Step = 302
}
}
if(Step = 305)
{
GuiControl, , Gui_NowState, [무기수리] 갈리드 체크 중
Get_Gold()
if(Gold <= 100000)
{
Step = 500
}
else
{
Step = 306
}
}
if(Step = 306)
{
GuiControl, , Gui_NowState, [무기수리] NPC 대화 중
Move_Repair()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
ShopOpendTime := A_TickCount
Step = 307
}
if(Step = 307)
{
GuiControl, , Gui_NowState, [무기수리] NPC 메뉴 체크 중
Check_NPCMenu()
if(NPCMenu = 1)
{
Check_NPCMenuPos()
if(NPCMenuRepairPosX != "" and NPCMenuRepairPosY != "")
{
Sleep, 500
PostClick(NPCMenuRepairPosX,NPCMenuRepairPosY)
RepairClickedTime := A_TickCount
Step = 308
}
}
if(NPCMenu = 0)
{
ShopOpenTime := A_TickCount - ShopOpendTime
if(ShopOpenTime >= 10000)
{
Step = 306
}
}
}
if(Step = 308)
{
GuiControl, , Gui_NowState, [무기수리] 수리창 체크 중
Check_Shop()
if(Repair = 1)
{
Sleep, 500
Step = 309
}
if(Repair = 0)
{
RepairClickTime := A_TickCount - RepairClickedTime
if(RepairClickTime >= 10000)
{
Step = 312
}
}
}
if(Step = 309)
{
GuiControl, , Gui_NowState, [무기수리] 수리 중
PostClick(355,320)
Sleep, 2000
Step = 310
}
if(Step = 310)
{
GuiControl, , Gui_NowState, [무기수리] 수리창 닫는 중
Check_Shop()
if(Repair = 1)
{
PostMessage, 0x100, 27, 65537, , ahk_pid %jPID%
PostMessage, 0x101, 27, 65537, , ahk_pid %jPID%
Sleep, 1000
Step = 311
}
}
if(Step = 311)
{
GuiControl, , Gui_NowState, [무기수리] 수리창 닫힘 체크 중
Check_Shop()
if(Repair = 0)
{
Step = 312
}
if(Repair = 1)
{
Step = 310
}
}
if(Step = 312)
{
GuiControl, , Gui_NowState, [무기수리] 무기상점 밖으로 이동 중
Loop,3
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
Sleep, 500
}
Step = 313
}
if(Step = 313)
{
GuiControl, , Gui_NowState, [무기수리] 지역 체크 중
Get_Location()
IfInString,Location,석공소
{
AltR()
Step = 311
}
IfNotInString,Location,석공소
{
Step = 314
}
}
if(Step = 314)
{
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(349,233)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Sleep, 500
Step = 315
}
if(Step = 315)
{
if(HuntPlace = 1)
{
RCC += 1
Step = 11
}
if(HuntPlace = 2)
{
Step = 1002
}
}
if(Step = 400)
{
GuiControl, , Gui_NowState, [물약구매] 마법상점으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(470,335)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 401
}
if(Step = 401)
{
GuiControl, , Gui_NowState, [물약구매] 위치 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 402
}
}
}
if(Step = 402)
{
Get_Location()
IfInString,Location,마법상점
{
Step = 403
}
IfNotInString,Location,마법상점
{
AltR()
Step = 400
}
}
if(Step = 403)
{
GuiControl, , Gui_NowState, [물약구매] NPC 위치로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(402,293)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 404
}
if(Step = 404)
{
GuiControl, , Gui_NowState, [물약구매] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 405
}
}
}
if(Step = 405)
{
GuiControl, , Gui_NowState, [물약구매] 캐릭터 위치 체크 중
Get_Pos()
if(PosX >= 20 and PosX <= 51 and PosY >= 10 and PosY <= 24)
{
Step = 406
}
if(!(PosX >= 20 and PosX <= 51 and PosY >= 10 and PosY <= 24))
{
Step = 403
}
}
if(Step = 406)
{
GuiControl, , Gui_NowState, [물약구매] 갈리드 체크 중
Get_Gold()
if(Gold <= 100000)
{
Step = 500
}
else
{
Step = 407
}
}
if(Step = 407)
{
GuiControl, , Gui_NowState, [물약구매] NPC 대화 중
Move_Buy()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x101, 53, 393217, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
ShopOpendTime := A_TickCount
Step = 408
}
if(Step = 408)
{
GuiControl, , Gui_NowState, [물약구매] NPC 메뉴 체크 중
Check_NPCMenu()
if(NPCMenu = 1)
{
Check_NPCMenuPos()
if(NPCMenuBuyPosX != "" and NPCMenuBuyPosY != "")
{
Sleep, 500
PostClick(NPCMenuBuyPosX,NPCMenuBuyPosY)
Step = 409
}
}
if(NPCMenu = 0)
{
ShopOpenTime := A_TickCount - ShopOpendTime
if(ShopOpenTime >= 10000)
{
AltR()
Sleep, 2000
Step = 403
}
}
}
if(Step = 409)
{
GuiControl, , Gui_NowState, [물약구매] 구매창 체크 중
Check_Shop()
if(Buy = 1)
{
Sleep, 500
Step = 410
}
}
if(Step = 410)
{
GuiControl, , Gui_NowState, [물약구매] 물약 구매 중
PostClick(180,60)
Sleep, 100
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x100, 13, 1835009, , ahk_pid %jPID%
PostMessage, 0x101, 13, 1835009, , ahk_pid %jPID%
MedCount := Gui_MedCount + 20
GuiControl, , Gui_MedCount, %MedCount%
Sleep, 2000
Step = 411
}
if(Step = 411)
{
GuiControl, , Gui_NowState, [물약구매] 구매창 닫는 중
Check_Shop()
if(Buy = 1)
{
Sleep, 1000
PostMessage, 0x100, 27, 65537, , ahk_pid %jPID%
PostMessage, 0x101, 27, 65537, , ahk_pid %jPID%
Sleep, 1000
Step = 412
}
}
if(Step = 412)
{
GuiControl, , Gui_NowState, [물약구매] 구매창 닫힘 체크 중
Check_Shop()
if(Buy = 0)
{
Step = 413
}
if(Buy = 1)
{
Step = 411
}
}
if(Step = 413)
{
GuiControl, , Gui_NowState, [물약구매] 마법상점 밖으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(400,324)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 414
}
if(Step = 414)
{
GuiControl, , Gui_NowState, [물약구매] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 415
}
}
}
if(Step = 415)
{
GuiControl, , Gui_NowState, [물약구매] 지역 체크 중
Get_Location()
IfInString,Location,마법상점
{
AltR()
Step = 412
}
IfNotInString,Location,마법상점
{
Step = 1002
}
}
if(Step = 500)
{
GuiControl, , Gui_NowState, [골드바] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal = 1
Step = 501
}
}
if(Step = 501)
{
GuiControl, , Gui_NowState, [골드바] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 502
}
}
if(Step = 502)
{
GuiControl, , Gui_NowState, [골드바] 은행으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(358,372)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 503
}
if(Step = 503)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 504
}
}
}
if(Step = 504)
{
GuiControl, , Gui_NowState, [골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
Step = 505
}
IfNotInString,Location,은행
{
AltR()
Step = 502
}
}
if(Step = 505)
{
GuiControl, , Gui_NowState, [골드바] NPC 위치로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(380,302)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 506
}
if(Step = 506)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 507
}
}
}
if(Step = 507)
{
GuiControl, , Gui_NowState, [골드바] 캐릭터 위치 체크 중
Get_Pos()
if(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29)
{
Step = 508
}
if(!(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29))
{
Step = 505
}
}
if(Step = 508)
{
GuiControl, , Gui_NowState, [골드바] NPC 대화 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Step = 509
}
if(Step = 509)
{
GuiControl, , Gui_NowState, [골드바] 골드바 판매 중
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,87)
Sleep, 500
}
IfInString,NPCMsg,팔건가?
{
Sleep, 500
PostClick(121,80)
Sleep, 500
Step = 510
}
IfInString,NPCMsg,속이려는건가
{
GuiControl, , Gui_NowState, 골드바가 없어 종료합니다.
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Step = 510)
{
GuiControl, , Gui_NowState, [골드바] 골드바 판매 완료
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,100)
Sleep, 500
Step = 511
}
}
if(Step = 511)
{
GuiControl, , Gui_NowState, [골드바] 은행 밖으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(400,324)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 512
}
if(Step = 512)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 513
}
}
}
if(Step = 513)
{
GuiControl, , Gui_NowState, [골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
AltR()
Step = 511
}
IfNotInString,Location,은행
{
if(Grade = 1)
{
Grade = 0
Step = 602
return
}
if(HuntPlace = 1)
{
Step = 11
}
if(HuntPlace = 2)
{
Step = 1002
}
}
}
if(Step = 550)
{
GuiControl, , Gui_NowState, [골드바] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal = 1
Step = 551
}
}
if(Step = 551)
{
GuiControl, , Gui_NowState, [골드바] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 552
}
}
if(Step = 552)
{
GuiControl, , Gui_NowState, [골드바] 은행으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(358,372)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 553
}
if(Step = 553)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 554
}
}
}
if(Step = 554)
{
GuiControl, , Gui_NowState, [골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
Step = 555
}
IfNotInString,Location,은행
{
AltR()
Step = 552
}
}
if(Step = 555)
{
GuiControl, , Gui_NowState, [골드바] NPC 위치로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(380,302)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 556
}
if(Step = 556)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 557
}
}
}
if(Step = 557)
{
GuiControl, , Gui_NowState, [골드바] 캐릭터 위치 체크 중
Get_Pos()
if(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29)
{
Step = 558
}
if(!(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29))
{
Step = 555
}
}
if(Step = 558)
{
GuiControl, , Gui_NowState, [골드바] NPC 대화 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Step = 559
}
if(Step = 559)
{
GuiControl, , Gui_NowState, [골드바] 골드바 판매 중
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,87)
Sleep, 500
}
IfInString,NPCMsg,팔건가?
{
Sleep, 500
PostClick(121,80)
Sleep, 500
Step = 560
}
IfInString,NPCMsg,속이려는건가
{
GuiControl, , Gui_NowState, 골드바가 없어 종료합니다.
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Step = 560)
{
GuiControl, , Gui_NowState, [골드바] 골드바 판매 완료
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,100)
Sleep, 500
Step = 561
}
}
if(Step = 561)
{
GuiControl, , Gui_NowState, [골드바] 은행 밖으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(400,324)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 562
}
if(Step = 562)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 563
}
}
}
if(Step = 563)
{
GuiControl, , Gui_NowState, [골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
AltR()
Step = 561
}
IfNotInString,Location,은행
{
if(Grade = 1)
{
Grade = 0
Step = 652
return
}
if(HuntPlace = 1)
{
Step = 11
}
if(HuntPlace = 2)
{
Step = 1002
}
}
}
if(Step = 800)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal = 1
Step = 801
}
}
if(Step = 801)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 802
}
}
if(Step = 802)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 은행으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(358,372)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 803
}
if(Step = 803)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 804
}
}
}
if(Step = 804)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
Step = 805
}
IfNotInString,Location,은행
{
AltR()
Step = 802
}
}
if(Step = 805)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] NPC 위치로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(380,302)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 806
}
if(Step = 806)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 807
}
}
}
if(Step = 807)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 캐릭터 위치 체크 중
Get_Pos()
if(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29)
{
Step = 808
}
if(!(PosX >= 16 and PosX <= 40 and PosY >= 9 and PosY <= 29))
{
Step = 805
}
}
if(Step = 808)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] NPC 대화 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 54, 458753, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Step = 809
}
if(Step = 809)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 골드바 판매 중
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,87)
Sleep, 500
}
IfInString,NPCMsg,팔건가?
{
Sleep, 500
PostClick(121,80)
Sleep, 500
Step = 810
}
IfInString,NPCMsg,속이려는건가
{
GuiControl, , Gui_NowState, 골드바가 없어 종료합니다.
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Step = 810)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 골드바 판매 완료
Check_NPCMsg()
IfInString,NPCMsg,사고 팔아요
{
Sleep, 500
PostClick(135,100)
Sleep, 500
Step = 811
}
}
if(Step = 811)
{
GuiControl, , Gui_NowState, [강제 그렐 골드바] 은행 밖으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(400,324)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 812
}
if(Step = 812)
{
GuiControl, , Gui_NowState, [골드바] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 813
}
}
}
if(Step = 813)
{
GuiControl, , Gui_NowState, [골드바] 지역 체크 중
Get_Location()
IfInString,Location,은행
{
AltR()
Step = 811
}
IfNotInString,Location,은행
{
Step = 702
return
}
}
if(Step = 600)
{
GuiControl, , Gui_NowState, [그레이드] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 601
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 601
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 601
return
}
}
}
if(Step = 601)
{
GuiControl, , Gui_NowState, [그레이드] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 602
}
IfInString,Location,[베타차원] 포프레스네 마을
{
Step = 602
}
IfInString,Location,[감마차원] 포프레스네 마을
{
Step = 602
}
}
if(Step = 602)
{
GuiControl, , Gui_NowState, [그레이드] 신전으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(406,180)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 603
}
if(Step = 603)
{
GuiControl, , Gui_NowState, [그레이드] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 604
}
}
}
if(Step = 604)
{
GuiControl, , Gui_NowState, [그레이드] 지역 체크 중
Get_Location()
IfInString,Location,신전
{
Step = 605
}
IfNotInString,Location,신전
{
AltR()
Step = 602
}
}
if(Step = 605)
{
GuiControl, , Gui_NowState, [그레이드] 갈리드 체크 중
Get_Gold()
if(Gold < 1000000)
{
if(Gui_Grade = 1)
{
Grade = 1
Step = 500
}
if(Gui_Grade = 0)
{
GuiControl, , Gui_NowState, 갈리드가 부족하여 종료합니다.
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Gold >= 1000000)
{
Step = 606
}
}
if(Step = 606)
{
GuiControl, , Gui_NowState, [그레이드] 기도 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
Step = 607
}
if(Step = 607)
{
GuiControl, , Gui_NowState, [그레이드] 그레이드 하는 중
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 92)
{
IfInString,NPCMsg,무엇을 도와드릴까요
{
Sleep, 500
PostClick(129,77)
Sleep, 500
}
}
if(FormNumber = 68)
{
IfInString,NPCMsg,맞습니까
{
Sleep, 500
PostClick(120,73)
Sleep, 500
Step = 608
}
}
if(FormNumber = 56)
{
IfInString,NPCMsg,어떤 것을 도와 드릴까요
{
Sleep, 500
PostClick(135,70)
Sleep, 500
}
IfInString,NPCMsg,선택하세요
{
Sleep, 500
PostClick(134,57)
Sleep, 500
}
IfInString,NPCMsg,맞습니까
{
Sleep, 500
PostClick(123,69)
Sleep, 500
Step = 608
}
}
if(FormNumber = 44)
{
IfInString,NPCMsg,올리시겠습니까
{
Sleep, 500
PostClick(122,63)
Sleep, 500
}
}
if(FormNumber = 38)
{
IfWinNotActive,ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
if(WeaponAbility1 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName1)
WeaponAbility1 = 0
Sleep, 1000
return
}
if(WeaponAbility2 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName2)
WeaponAbility2 = 0
Sleep, 1000
return
}
if(WeaponAbility3 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName3)
WeaponAbility3 = 0
Sleep, 1000
return
}
if(WeaponAbility4 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName4)
WeaponAbility4 = 0
Sleep, 1000
return
}
if(WeaponAbility5 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName5)
WeaponAbility5 = 0
Sleep, 1000
return
}
if(WeaponAbility6 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName6)
WeaponAbility6 = 0
Sleep, 1000
return
}
if(WeaponAbility7 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName7)
WeaponAbility7 = 0
Sleep, 1000
return
}
if(WeaponAbility8 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName8)
WeaponAbility8 = 0
Sleep, 1000
return
}
if(WeaponAbility9 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName9)
WeaponAbility9 = 0
Sleep, 1000
return
}
if(WeaponAbility10 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName10)
WeaponAbility10 = 0
Sleep, 1000
return
}
if(WeaponAbility11 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName11)
WeaponAbility11 = 0
Sleep, 1000
return
}
if(WeaponAbility12 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName12)
WeaponAbility12 = 0
Sleep, 1000
return
}
if(WeaponAbility13 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName13)
WeaponAbility13 = 0
Sleep, 1000
return
}
if(WeaponAbility14 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName14)
WeaponAbility14 = 0
Sleep, 1000
return
}
if(WeaponAbility15 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName15)
WeaponAbility15 = 0
Sleep, 1000
return
}
if(WeaponAbility16 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName16)
WeaponAbility16 = 0
Sleep, 1000
return
}
if(WeaponAbility17 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName17)
WeaponAbility17 = 0
Sleep, 1000
return
}
if(WeaponAbility18 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName18)
WeaponAbility18 = 0
Sleep, 1000
return
}
if(WeaponAbility19 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName19)
WeaponAbility19 = 0
Sleep, 1000
return
}
if(WeaponAbility20 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName20)
WeaponAbility20 = 0
Sleep, 1000
return
}
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
if(WeaponAbility1 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName1)
WeaponAbility1 = 0
Sleep, 1000
return
}
if(WeaponAbility2 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName2)
WeaponAbility2 = 0
Sleep, 1000
return
}
if(WeaponAbility3 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName3)
WeaponAbility3 = 0
Sleep, 1000
return
}
if(WeaponAbility4 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName4)
WeaponAbility4 = 0
Sleep, 1000
return
}
if(WeaponAbility5 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName5)
WeaponAbility5 = 0
Sleep, 1000
return
}
if(WeaponAbility6 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName6)
WeaponAbility6 = 0
Sleep, 1000
return
}
if(WeaponAbility7 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName7)
WeaponAbility7 = 0
Sleep, 1000
return
}
if(WeaponAbility8 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName8)
WeaponAbility8 = 0
Sleep, 1000
return
}
if(WeaponAbility9 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName9)
WeaponAbility9 = 0
Sleep, 1000
return
}
if(WeaponAbility10 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName10)
WeaponAbility10 = 0
Sleep, 1000
return
}
if(WeaponAbility11 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName11)
WeaponAbility11 = 0
Sleep, 1000
return
}
if(WeaponAbility12 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName12)
WeaponAbility12 = 0
Sleep, 1000
return
}
if(WeaponAbility13 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName13)
WeaponAbility13 = 0
Sleep, 1000
return
}
if(WeaponAbility14 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName14)
WeaponAbility14 = 0
Sleep, 1000
return
}
if(WeaponAbility15 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName15)
WeaponAbility15 = 0
Sleep, 1000
return
}
if(WeaponAbility16 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName16)
WeaponAbility16 = 0
Sleep, 1000
return
}
if(WeaponAbility17 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName17)
WeaponAbility17 = 0
Sleep, 1000
return
}
if(WeaponAbility18 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName18)
WeaponAbility18 = 0
Sleep, 1000
return
}
if(WeaponAbility19 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName19)
WeaponAbility19 = 0
Sleep, 1000
return
}
if(WeaponAbility20 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName20)
WeaponAbility20 = 0
Sleep, 1000
return
}
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
if(WeaponAbility1 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName1)
WeaponAbility1 = 0
Sleep, 1000
return
}
if(WeaponAbility2 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName2)
WeaponAbility2 = 0
Sleep, 1000
return
}
if(WeaponAbility3 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName3)
WeaponAbility3 = 0
Sleep, 1000
return
}
if(WeaponAbility4 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName4)
WeaponAbility4 = 0
Sleep, 1000
return
}
if(WeaponAbility5 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName5)
WeaponAbility5 = 0
Sleep, 1000
return
}
if(WeaponAbility6 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName6)
WeaponAbility6 = 0
Sleep, 1000
return
}
if(WeaponAbility7 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName7)
WeaponAbility7 = 0
Sleep, 1000
return
}
if(WeaponAbility8 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName8)
WeaponAbility8 = 0
Sleep, 1000
return
}
if(WeaponAbility9 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName9)
WeaponAbility9 = 0
Sleep, 1000
return
}
if(WeaponAbility10 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName10)
WeaponAbility10 = 0
Sleep, 1000
return
}
if(WeaponAbility11 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName11)
WeaponAbility11 = 0
Sleep, 1000
return
}
if(WeaponAbility12 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName12)
WeaponAbility12 = 0
Sleep, 1000
return
}
if(WeaponAbility13 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName13)
WeaponAbility13 = 0
Sleep, 1000
return
}
if(WeaponAbility14 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName14)
WeaponAbility14 = 0
Sleep, 1000
return
}
if(WeaponAbility15 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName15)
WeaponAbility15 = 0
Sleep, 1000
return
}
if(WeaponAbility16 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName16)
WeaponAbility16 = 0
Sleep, 1000
return
}
if(WeaponAbility17 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName17)
WeaponAbility17 = 0
Sleep, 1000
return
}
if(WeaponAbility18 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName18)
WeaponAbility18 = 0
Sleep, 1000
return
}
if(WeaponAbility19 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName19)
WeaponAbility19 = 0
Sleep, 1000
return
}
if(WeaponAbility20 = 10000)
{
Sleep, 1000
SendWeaponName(Gui_WeaponName20)
WeaponAbility20 = 0
Sleep, 1000
return
}
}
}
}
if(Step = 608)
{
GuiControl, , Gui_NowState, [그레이드] 어빌 체크 중
if(Gui_1Muba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
if(Gui_2Muba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
if(Gui_3Muba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
if(Gui_2ButMuba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
if(Gui_3ButMuba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
if(Gui_4ButMuba = 1)
{
if(WeaponAbility1 = 10000 or WeaponAbility2 = 10000 or WeaponAbility3 = 10000 or WeaponAbility4 = 10000 or WeaponAbility5 = 10000 or WeaponAbility6 = 10000 or WeaponAbility7 = 10000 or WeaponAbility8 = 10000 or WeaponAbility9 = 10000  or WeaponAbility10 = 10000  or WeaponAbility11 = 10000  or WeaponAbility12 = 10000  or WeaponAbility13 = 10000  or WeaponAbility14 = 10000  or WeaponAbility15 = 10000  or WeaponAbility16 = 10000  or WeaponAbility17 = 10000  or WeaponAbility18 = 10000  or WeaponAbility19 = 10000  or WeaponAbility20 = 10000)
{
Step = 605
}
if(WeaponAbility1 != 10000 and WeaponAbility2 != 10000 and WeaponAbility3 != 10000 and WeaponAbility4 != 10000 and WeaponAbility5 != 10000 and WeaponAbility6 != 10000 and WeaponAbility7 != 10000 and WeaponAbility8 != 10000 and WeaponAbility9 != 10000 and WeaponAbility10 != 10000 and WeaponAbility11 != 10000 and WeaponAbility12 != 10000 and WeaponAbility13 != 10000 and WeaponAbility14 != 10000 and WeaponAbility15 != 10000 and WeaponAbility16 != 10000 and WeaponAbility17 != 10000 and WeaponAbility18 != 10000 and WeaponAbility19 != 10000 and WeaponAbility20 != 10000)
{
Step = 609
}
}
}
if(Step = 609)
{
GuiControl, , Gui_NowState, [그레이드] 신전 밖으로 이동 중
Loop,3
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
Sleep, 500
}
Step = 610
}
if(Step = 610)
{
GuiControl, , Gui_NowState, [그레이드] 지역 체크 중
Get_Location()
IfInString,Location,신전
{
AltR()
Step = 609
}
IfNotInString,Location,신전
{
if(Gui_HuntAuto = 1)
{
if(Gui_1Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_2Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_3Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2 and BWValue3 < Gui_LimitAbility3)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility35)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_2ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_3ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_4ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
}
if(Gui_HuntPonam = 1)
{
HuntPlace = 1
Step = 11
}
if(Gui_HuntPobuk = 1)
{
HuntPlace = 2
Step = 1002
}
}
}
if(Step = 650)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 651
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 651
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 651
return
}
}
}
if(Step = 651)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 652
}
IfInString,Location,[베타차원] 포프레스네 마을
{
Step = 652
}
IfInString,Location,[감마차원] 포프레스네 마을
{
Step = 652
}
}
if(Step = 652)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 신전으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(406,180)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 653
}
if(Step = 653)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 654
}
}
}
if(Step = 654)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 지역 체크 중
Get_Location()
IfInString,Location,신전
{
Step = 655
}
IfNotInString,Location,신전
{
AltR()
Step = 652
}
}
if(Step = 655)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 갈리드 체크 중
Get_Gold()
if(Gold < 1000000)
{
if(Gui_Grade = 1)
{
Grade = 1
Step = 550
}
if(Gui_Grade = 0)
{
GuiControl, , Gui_NowState, 갈리드가 부족하여 종료합니다.
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
Gui_Enable()
SetTimer, Hunt, Off
SetTimer, AttackCheck, Off
SetTimer, incineration, off
CheckPB = 0
return
}
}
if(Gold >= 1000000)
{
Step = 656
}
}
if(Step = 656)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 기도 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
Step = 657
}
if(Step = 657)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 그레이드 하는 중
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 92)
{
IfInString,NPCMsg,무엇을 도와드릴까요
{
Sleep, 500
PostClick(129,77)
Sleep, 500
}
}
if(FormNumber = 56)
{
IfInString,NPCMsg,어떤 것을 도와 드릴까요
{
Sleep, 500
PostClick(135,70)
Sleep, 500
}
IfInString,NPCMsg,선택하세요
{
Sleep, 500
PostClick(120,70)
Sleep, 500
}
IfInString,NPCMsg,맞습니까
{
Sleep, 500
PostClick(123,69)
Sleep, 500
Step = 658
}
}
if(FormNumber = 44)
{
IfInString,NPCMsg,올리시겠습니까
{
Sleep, 500
PostClick(122,63)
Sleep, 500
}
}
if(FormNumber = 38)
{
IfWinNotActive,ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
if(MagicAbility3 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName3)
MagicAbility3 = 0
Sleep, 1000
return
}
if(MagicAbility4 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName4)
MagicAbility4 = 0
Sleep, 1000
return
}
if(MagicAbility5 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName5)
MagicAbility5 = 0
Sleep, 1000
return
}
if(MagicAbility6 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName6)
MagicAbility6 = 0
Sleep, 1000
return
}
if(MagicAbility7 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName7)
MagicAbility7 = 0
Sleep, 1000
return
}
if(MagicAbility8 = 100)
{
Sleep, 1000
SendMagicName(Gui_MagicName8)
MagicAbility8 = 0
Sleep, 1000
return
}
}
}
if(Step = 658)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 어빌 체크 중
if(MagicAbility3 = 100 or MagicAbility4 = 100 or MagicAbility5 = 100 or MagicAbility6 = 100 or MagicAbility7 = 100 or MagicAbility8 = 100)
{
Step = 655
}
if(MagicAbility3 != 100 and MagicAbility4 != 100 and MagicAbility5 != 100 and MagicAbility6 != 100 and MagicAbility7 != 100 and MagicAbility3=8 != 100)
{
Step = 659
}
}
if(Step = 659)
{
GuiControl, , Gui_NowState, [스펠 그레이드] 신전 밖으로 이동 중
Set_MoveSpeed()
Loop,3
{
PostMessage, 0x100, 40, 22020097, , ahk_pid %jPID%
PostMessage, 0x101, 40, 22020097, , ahk_pid %jPID%
Sleep, 500
}
Step = 660
}
if(Step = 660)
{
GuiControl, , Gui_NowState, [그레이드] 지역 체크 중
Get_Location()
IfInString,Location,신전
{
AltR()
Step = 659
}
IfNotInString,Location,신전
{
if(Gui_HuntAuto = 1)
{
if(Gui_1Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_2Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_3Muba = 1)
{
if(BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2 and BWValue3 < Gui_LimitAbility3)
{
HuntPlace = 1
Step = 8
}
if(BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2 or BWValue3 >= Gui_LimitAbility35)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_2ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_3ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
if(Gui_4ButMuba = 1)
{
if(BWValue0 < Gui_LimitAbility0 and BWValue1 < Gui_LimitAbility1 and BWValue2 < Gui_LimitAbility2)
{
HuntPlace = 1
Step = 8
}
if(BWValue0 >= Gui_LimitAbility0 or BWValue1 >= Gui_LimitAbility1 or BWValue2 >= Gui_LimitAbility2)
{
HuntPlace = 2
Step = 8
}
}
}
if(Gui_HuntPonam = 1)
{
HuntPlace = 1
Step = 11
}
if(Gui_HuntPobuk = 1)
{
HuntPlace = 2
Step = 1002
}
}
}
if(Step = 700)
{
GuiControl, , Gui_NowState, [강제 그레이드] 라깃 사용 중
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 701
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 701
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
Step = 701
return
}
}
}
if(Step = 701)
{
GuiControl, , Gui_NowState, [강제 그레이드] 차원이동 체크 중
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Step = 702
}
IfInString,Location,[베타차원] 포프레스네 마을
{
Step = 702
}
IfInString,Location,[감마차원] 포프레스네 마을
{
Step = 702
}
}
if(Step = 702)
{
if(Gui_forceweapon = "선택")
{
GuiControl, , Gui_NowState, [강제 그레이드] 그레이드 어빌 선택 해주세요.
Sleep, 1000
step = 9
return
}
GuiControl, , Gui_NowState, [강제 그레이드] 신전으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(406,180)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 703
}
if(Step = 703)
{
GuiControl, , Gui_NowState, [강제 그레이드] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 704
}
}
}
if(Step = 704)
{
GuiControl, , Gui_NowState, [강제 그레이드] 지역 체크 중
Get_Location()
IfInString,Location,신전
{
Step = 705
}
IfNotInString,Location,신전
{
AltR()
Step = 702
}
}
if(Step = 705)
{
GuiControl, , Gui_NowState, [강제 그레이드] 갈리드 체크 중
Get_Gold()
if(Gold < 1000000)
{
Step = 800
}
if(Gold >= 1000000)
{
Step = 706
}
}
if(Step = 706)
{
GuiControl, , Gui_NowState, [강제 그레이드] 기도 중
Move_NPCTalkForm()
Sleep, 100
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 55, 524289, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 500
Step = 707
}
if(Step = 707)
{
GuiControl, , Gui_NowState, [강제 그레이드] 그레이드 하는 중
Check_FormNumber()
Check_NPCMsg()
if(FormNumber = 92)
{
IfInString,NPCMsg,무엇을 도와드릴까요
{
Sleep, 500
PostClick(129,77)
Sleep, 500
}
}
if(FormNumber = 68)
{
IfInString,NPCMsg,맞습니까
{
Sleep, 500
PostClick(120,73)
Sleep, 500
Step = 608
}
}
if(FormNumber = 56)
{
IfInString,NPCMsg,어떤 것을 도와 드릴까요
{
Sleep, 500
PostClick(135,70)
Sleep, 500
}
IfInString,NPCMsg,선택하세요
{
Sleep, 500
PostClick(134,57)
Sleep, 500
}
IfInString,NPCMsg,맞습니까
{
Sleep, 500
PostClick(123,69)
Sleep, 500
Step = 708
}
}
if(FormNumber = 44)
{
IfInString,NPCMsg,올리시겠습니까
{
Sleep, 500
PostClick(122,63)
Sleep, 500
}
}
if(FormNumber = 38)
{
IfWinNotActive,ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
if(Gui_forceweapon != "선택")
{
if(Gui_forceweapon = "격투")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Sleep, 1000
Send, rurxn{Enter}
WeaponAbility0 = 0
Sleep, 1000
return
}
if(Gui_forceweapon != "격투")
{
Sleep, 1000
SendWeaponName(Gui_forceweapon)
Sleep, 1000
return
}
}
}
}
if(Step = 708)
{
GuiControl, , Gui_NowState, [강제그레이드] 어빌 확인
GuiControl, choose, Gui_forceweapon, 선택
Step = 609
}
if(Step = 1000)
{
GuiControl, , Gui_NowState, [포북] 라깃 사용 중
value := jelan.write(0x0045D28F, 0x0F, "Char", aOffsets*)
value := jelan.write(0x0045D290, 0x84, "Char", aOffsets*)
value := jelan.write(0x0045D291, 0xC2, "Char", aOffsets*)
value := jelan.write(0x0045D292, 0x00, "Char", aOffsets*)
value := jelan.write(0x0045D293, 0x00, "Char", aOffsets*)
CheckPB = 0
Send, {F16 Down}
Send, {F16 Up}
Send, {F16 Down}
Send, {F16 Up}
if(FirstPortal = 1)
{
if(Gui_CheckUseParty = 1)
{
Random, CountPortal, 1, 2
}
if(Gui_CheckUseParty = 0)
{
Random, CountPortal, 0, 2
}
FirstPortal = 1
}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Check_Ras()
if(Ras = 0)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 200
PostMessage, 0x100, 48, 720897, , ahk_pid %jPID%
PostMessage, 0x101, 48, 720897, , ahk_pid %jPID%
Sleep, 300
}
if(Ras = 1 and SelectRas = 0)
{
PostClick(625,365)
Sleep, 100
}
if(Ras = 1 and SelectRas = 1)
{
if(CountPortal = 0)
{
PostClick(630,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal += 1
Step = 1001
return
}
if(CountPortal = 1)
{
PostClick(645,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal += 1
Step = 1001
return
}
if(CountPortal = 2)
{
PostClick(660,345)
RasCount := Gui_RasCount-1
GuiControl, , Gui_RasCount, %RasCount%
CountPortal = 0
Step = 1001
return
}
}
}
if(Step = 1001)
{
GuiControl, , Gui_NowState, [포북] 차원이동 검사 중
if(Gui_CheckUseMagic = 1)
{
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
Get_Location()
IfInString,Location,[알파차원] 포프레스네 마을
{
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Step = 1002
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
IfInString,Location,[베타차원] 포프레스네 마을
{
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Step = 1002
}
if(Gui_CheckUseParty = 1)
{
CountPortal = 1
}
Send, {F13 Down}
Sleep, 30
Send, {F13 Up}
IfInString,Location,[감마차원] 포프레스네 마을
{
getNpcidFromFile()
if(CTC !=rCTC)
{
}
Step = 1002
}
}
if(Step = 1002)
{
Mapnumber = 1
GuiControl, , Gui_NowState, [포북] 빛나는가루 소각 중
if(Gui_jjON = 1)
{
Loop,50
{
SetFormat, integer, H
invenslot += 4
itemm := jelan.readString(0x0058DAD4, 50, "UTF-16", 0x178, 0xBE, 0x8, invenslot, 0x8, 0x8, 0x0)
SetFormat, integer, D
IfInString,itemm,빛나는가루
{
itemnum += 1
}
}
if(itemnum > 2)
{
inciloop := itemnum - 2
loop,%inciloop%
{
value := jelan.writeString(0x005909C0, "빛나는가루" , "UTF-16")
incinerate()
Sleep, 1000
}
}
itemnum =
invenslot =
}
GuiControl, , Gui_NowState, [포남] 라깃 갯수 체크 중
if(Gui_CheckUseMagic = 1)
{
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
Send, {F17 Down}
Sleep, 200
Send, {F17 UP}
}
Get_MsgM()
Get_Perfect()
RasCount := Gui_RasCount
if(RasCount <= 5)
{
Step = 100
}
if(RasCount > 5)
{
Step = 1055
}
}
if(Step = 1055)
{
GuiControl, , Gui_NowState, [포북] 메모리 점유율 확인 중
GetPrivateWorkingSet(jPID)
if(TotalPhy > 2000000)
{
if(byte > 1000000)
{
step = 10000
}
if(byte <= 1000000)
{
step = 1003
}
}
if(TotalPhy <= 2000000)
{
if(byte > 620000)
{
step = 10000
}
if(byte <= 620000)
{
step = 1003
}
}
}
if(Step = 1003)
{
GuiControl, , Gui_NowState, [포북] 파티 설정 중
Check_State()
if(State = 1)
{
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
}
if(Gui_PartyOff = 1)
{
Move_StateForMount()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
PostDClick(190,310)
Sleep, 100
PostDClick(225,310)
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 100
}
Move_State()
Sleep, 100
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 80, 1638401, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
Sleep, 500
Check_State()
Check_StatePos()
if(StatePosX = 565 and StatePosY = 655 and State = 1)
{
if(Gui_CheckUseParty = 1)
{
Step = 910
}
if(Gui_CheckUseParty = 0)
{
Step = 1004
}
}
}
if(Step = 1004)
{
if(Gui_CheckUseParty = 1)
{
party()
}
GuiControl, , Gui_NowState, [포북] 포프레스네 북쪽으로 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(550,130)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
if(BWValue0 = 9999)
{
BWValue0 := ReadAbility("격투")
SetFormat, Float, 0.2
TempAbility := BWValue0 / 100
GuiControl, , Gui_BasicWValue0, %TempAbility%
SetFormat, Float, 0
}
if(BWValue1 = 9999)
{
BWValue1 := ReadAbility(Gui_Weapon1)
SetFormat, Float, 0.2
TempAbility := BWValue1 / 100
GuiControl, , Gui_BasicWValue1, %TempAbility%
SetFormat, Float, 0
}
if(BWValue2 = 9999)
{
BWValue2 := ReadAbility(Gui_Weapon2)
SetFormat, Float, 0.2
TempAbility := BWValue2 / 100
GuiControl, , Gui_BasicWValue2, %TempAbility%
SetFormat, Float, 0
}
if(BWValue3 = 9999)
{
BWValue0 := ReadAbility(Gui_Weapon3)
SetFormat, Float, 0.2
TempAbility := BWValue3 / 100
GuiControl, , Gui_WeaponValue3, %TempAbility%
SetFormat, Float, 0
}
Step = 1005
}
if(Step = 1005)
{
GuiControl, , Gui_NowState, [포북] 움직임 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 1006
}
}
}
if(Step = 1006)
{
GuiControl, , Gui_NowState, [포북] 지역 체크 중
Get_Location()
IfInString,Location,북쪽 필드
{
RCC = 0
Step = 1007
}
IfNotInString,Location,북쪽 필드
{
AltR()
Step = 1004
}
}
if(Step = 1007)
{
GuiControl, , Gui_NowState, [포북] 포북 파수꾼으로 이동 중
if(Gui_jjOn = 1)
{
Send, {F18 Down}
Sleep, 40
Send, {F18 Up}
Sleep, 10
Send, {F18 Down}
Sleep, 40
Send, {F18 Up}
PickUp_itemsetPN()
}
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
PostClick(520,330)
OpenMap()
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 1008
}
if(Step = 1008)
{
GuiControl, , Gui_NowState, [포북] 움직임 체크 중
Get_Location()
IfNotInString,Location,북쪽 필드
{
AltR()
Step = 1000
}
Check_Moving()
if(Moving = 0)
{
Sleep, 1000
Check_Moving()
if(Moving = 0)
{
Step = 1009
}
}
}
if(Step = 1009)
{
GuiControl, , Gui_NowState, [포북] 캐릭터 위치 체크 중
Get_Location()
IfNotInString,Location,북쪽 필드
{
AltR()
Step = 1000
}
Check_Moving()
Get_Pos()
Get_MovePos()
if((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2))
{
MoveWaitCount = 0
pbtalkcheck += 1
pbtalkcheck1 := A_TickCount
Step = 1010
}
if(!((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2)))
{
if(MoveWaitCount >= 3)
{
MoveWaitCount = 0
AltR()
Step = 1000
}
else
{
AltR()
Step = 1007
MoveWaitCount += 1
}
}
}
if(Step = 1030)
{
GuiControl, , Gui_NowState, [포북] 매끄러운 피부 갱신중
CheckPB = 0
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Sleep, 300
CheckPB = 0
GuiControl, , Gui_NowState, [포남] 빛나는가루 소각 중
if(Gui_jjON = 1)
{
Loop,50
{
SetFormat, integer, H
invenslot += 4
itemm := jelan.readString(0x0058DAD4, 50, "UTF-16", 0x178, 0xBE, 0x8, invenslot, 0x8, 0x8, 0x0)
SetFormat, integer, D
IfInString,itemm,빛나는가루
{
itemnum += 1
}
}
if(itemnum > 2)
{
inciloop := itemnum - 2
loop,%inciloop%
{
value := jelan.writeString(0x005909C0, "빛나는가루" , "UTF-16")
incinerate()
Sleep, 1000
}
}
itemnum =
invenslot =
}
Step = 1056
}
if(Step = 1056)
{
GuiControl, , Gui_NowState, [포북] 메모리 점유율 확인 중
GetPrivateWorkingSet(jPID)
if(TotalPhy > 2000000)
{
if(byte > 1000000)
{
step = 10000
}
if(byte <= 1000000)
{
pbtalkcheck1 := A_TickCount
pbtalkcheck += 1
step = 1031
}
}
if(TotalPhy <= 2000000)
{
if(byte > 620000)
{
step = 10000
}
if(byte <= 620000)
{
pbtalkcheck1 := A_TickCount
pbtalkcheck += 1
step = 1031
}
}
}
if(Step = 1031)
{
GuiControl, , Gui_NowState, [포북] NPC 대화 중
value := jelan.write(0x00527B1C, CCD, "UInt")
Sleep, 500
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 900
Check_FormNumber()
if(FormNumber = 117)
{
Step = 1032
}
}
if(Step = 1032)
{
GuiControl, , Gui_NowState, [포북] 매끄러운 피부 받는 중
Sleep, 400
Check_FormNumber()
Sleep, 100
if(FormNumber = 117)
{
Sleep, 800
PostClick(110,85)
Sleep, 800
}
if(FormNumber = 93)
{
Sleep, 800
PostClick(130,90)
Sleep, 800
}
if(FormNumber = 81)
{
Sleep, 800
PostClick(120,80)
Sleep, 800
step = 1033
}
}
if(Step = 1033)
{
GuiControl, , Gui_NowState, [포북] NPC 대화 종료
Check_FormNumber()
Sleep, 600
if(FormNumber = 117)
{
Sleep, 500
PostClick(85,113)
Sleep, 500
newTime = %A_Now%
EnvAdd, newTime, 27, Minutes
FormatTime, newTime1, %newTime%, yyyyMMddHHmm
CheckPB = 1
pbtalkcheck = 0
Sleep, 50
step = 1016
}
}
if(Step = 1010)
{
Get_Location()
GuiControl, , Gui_NowState, [포북] NPC 대화 중
Move_NPCTalkForm()
callid = 1
Sleep, 1000
PixelSearch, MobX, MobY, 410, 100, 580, 235, 0xEF8AFF, 1, Fast
if(ErrorLevel = 1)
{
PostMessage, 0x100, 17, 1900545, , ahk_pid %jPID%
PostMessage, 0x100, 56, 589825, , ahk_pid %jPID%
PostMessage, 0x101, 56, 589825, , ahk_pid %jPID%
PostMessage, 0x101, 17, 1900545, , ahk_pid %jPID%
Sleep, 800
Check_FormNumber()
if(FormNumber = 117)
{
Check_OID()
Step = 1011
}
}
if(ErrorLevel = 0)
{
PostClick(MobX,MobY)
PostMove(470,575)
Sleep, 800
Check_FormNumber()
if(FormNumber = 117)
{
Check_OID()
Step = 1011
}
}
}
if(Step = 1011)
{
GuiControl, , Gui_NowState, [포북] 매끄러운 피부 받는 중
Sleep, 400
Check_FormNumber()
Sleep, 100
if(FormNumber = 117)
{
Sleep, 800
PostClick(110,85)
Sleep, 800
}
if(FormNumber = 93)
{
Sleep, 800
PostClick(130,90)
Sleep, 800
}
if(FormNumber = 81)
{
Sleep, 800
PostClick(120,80)
Sleep, 800
step = 1012
}
}
if(Step = 1012)
{
GuiControl, , Gui_NowState, [포북] NPC 대화 종료
Check_FormNumber()
Sleep, 300
if(FormNumber = 117)
{
Sleep, 800
PostClick(85,113)
Sleep, 800
newTime = %A_Now%
EnvAdd, newTime, 27, Minutes
FormatTime, newTime1, %newTime%, yyyyMMddHHmm
CheckPB = 1
pbtalkcheck = 0
Sleep, 50
step = 1013
}
}
if(Step = 1013)
{
GuiControl, , Gui_NowState, [포북] 맵 이동 중
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Move_Map()
Sleep, 100
OpenMap()
PostClick(480,204)
CharMovePobuk()
OpenMap()
PostMove(495,577)
Sleep, 500
Check_Map()
if(Map = 1)
{
OpenMap()
Sleep, 100
}
Step = 1014
}
if(Step = 1014)
{
GuiControl, , Gui_NowState, [포북] 움직임 체크 중
Check_Moving()
Get_Pos()
Get_MovePos()
if(Moving = 0)
{
Sleep, 200
Check_Moving()
if(Moving = 0)
{
Step = 1015
}
}
if((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2))
{
MoveWaitCount = 0
Step = 1016
}
}
if(Step = 1015)
{
Get_Pos()
Get_MovePos()
if((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2))
{
MoveWaitCount = 0
Step = 1016
}
if(!((PosX >= MovePosX-2 and PosX <= MovePosX+2) and (PosY >= MovePosY-2 and PosY <= MovePosY+2)))
{
if(MoveWaitCount >= 2)
{
MoveWaitCount = 0
Step = 1000
}
else
{
Step = 1016
}
}
}
if(Step = 1016)
{
GuiControl, , Gui_NowState, [포북] 몹 찾는 중
IfWinNotActive, ahk_pid %jPID%
{
WinActivate, ahk_pid %jPID%
}
PixelSearch, MobX, MobY, 381, 185, 410, 260, 0x316D9C, 1, *ScanBR
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 360, 209, 437, 236, 0x316D9C, 1, *ScanLB
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 362, 186, 432, 255, 0x316D9C, 1, *ScanLT
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 333, 161, 460, 281, 0x316D9C, 1, *ScanRT
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 315, 138, 483, 305, 0x316D9C, 1, *ScanLT
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 260, 92, 533, 352, 0x316D9C, 1, *ScanRT
if(ErrorLevel = 1)
{
PixelSearch, MobX, MobY, 214, 44, 580, 400, 0x316D9C, 1, *ScanLT
}
}
}
}
}
}
if(ErrorLevel = 0)
{
PostClick(MobX,MobY)
PostMove(470,575)
WinGetPos, ElanciaClientX, ElanciaClientY, Width, Height, ahk_pid %jPID%
SplashX := MobX + ElanciaClientX - 13
SplashY := MobY + ElanciaClientY + 15
SplashImage, %MobNumber%:, b X%SplashX% Y%SplashY% W35 H32 CW000000
MobNumber += 1
if(MobNumber >= 11)
{
MobNumber = 1
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 1013
return
}
AttackLoopCount = 0
AttackCount = 0
Sleep, 500
movmob := A_TickCount
Step = 1019
return
}
if(ErrorLevel = 1)
{
MobNumber = 1
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 1013
return
}
}
if(Step = 1018)
{
GuiControl, , Gui_NowState, [포북] 몹 공격 체크 중
AttackLoopCount += 1
Check_Attack()
if(Attack = 0)
{
AttackCount += 1
}
if(Attack = 1 or Attack = 2)
{
AttackCount = 0
}
if(AttackLoopCount >= 10)
{
if(AttackCount > 5)
{
AttackLoopCount = 0
AttackCount = 0
Step = 1016
}
else
{
MobNumber = 1
AttackLoopCount = 0
AttackCount = 0
SplashImage, 1: off
SplashImage, 2: off
SplashImage, 3: off
SplashImage, 4: off
SplashImage, 5: off
SplashImage, 6: off
SplashImage, 7: off
SplashImage, 8: off
SplashImage, 9: off
SplashImage, 10: off
Step = 1026
}
}
}
if(Step = 1019)
{
GuiControl, , Gui_NowState, [포북] 몹 근접 체크 중
Check_Moving()
if(Moving = 0)
{
Sleep, 200
Check_Moving()
if(Moving = 0)
{
AltR()
Step = 1018
}
}
movmob2 := A_TickCount - movmob
if(movmob2 >= 1700)
{
Sleep, 100
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 1016
}
}
if(Step = 1026)
{
GuiControl, , Gui_NowState, [포북] 무바 중
if(Gui_1Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(RepairWeaponCount1 >= 5)
{
RepairWeaponCount1 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 240
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 240
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
}
if(Gui_2Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 = 0
}
MubaStep = 1
return
}
}
if(Gui_3Muba = 1)
{
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5 or RepairWeaponCount3 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
RepairWeaponCount3 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount2 = 0
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(TempWeapon = Weapon)
{
TempWeapon := Weapon
RepairWeaponCount3 += 1
}
if(TempWeapon != Weapon)
{
TempWeapon := Weapon
RepairWeaponCount3 = 0
}
MubaStep = 1
return
}
}
if(Gui_2ButMuba = 1)
{
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(RepairWeaponCount1 >= 5)
{
RepairWeaponCount1 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
if(Gui_3ButMuba = 1)
{
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount2 += 1
}
if(Weapon != 0)
{
RepairWeaponCount2 = 0
}
MubaStep = 4
return
}
if(MubaStep = 4)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
if(Gui_4ButMuba = 1)
{
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(RepairWeaponCount1 >= 5 or RepairWeaponCount2 >= 5 or RepairWeaponCount3 >= 5)
{
RepairWeaponCount1 = 0
RepairWeaponCount2 = 0
RepairWeaponCount3 = 0
MapNumber = 1
PostMessage, 0x100, 9, 983041, , ahk_pid %jPID%
PostMessage, 0x101, 9, 983041, , ahk_pid %jPID%
Step = 300
return
}
if(MubaStep = 1)
{
PostMessage, 0x100, 49, 131073, , ahk_pid %jPID%
PostMessage, 0x101, 49, 131073, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon1)
{
BWValue1 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon1 = "현금" or Gui_Weapon1 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount1 += 1
}
if(Weapon != 0)
{
RepairWeaponCount1 = 0
}
MubaStep = 2
return
}
if(MubaStep = 2)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 3
return
}
if(MubaStep = 3)
{
PostMessage, 0x100, 50, 196609, , ahk_pid %jPID%
PostMessage, 0x101, 50, 196609, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon2)
{
BWValue2 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon2 = "현금" or Gui_Weapon2 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount2 += 1
}
if(Weapon != 0)
{
RepairWeaponCount2 = 0
}
MubaStep = 4
return
}
if(MubaStep = 4)
{
WPD()
Sleep, 100
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 5
return
}
if(MubaStep = 5)
{
PostMessage, 0x100, 51, 262145, , ahk_pid %jPID%
PostMessage, 0x101, 51, 262145, , ahk_pid %jPID%
Sleep, 444
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Sleep, 444
ReadAbilityNameValue()
if(AbilityName = Gui_Weapon3)
{
BWValue3 := AbilityValue
}
if(Gui_CheckUseMagic = 1)
{
if(Gui_Weapon3 = "현금" or Gui_Weapon3 =  "스태프")
{
RemoteM()
}
}
Check_Weapon()
if(Weapon = 0)
{
RepairWeaponCount3 += 1
}
if(Weapon != 0)
{
RepairWeaponCount3 = 0
}
MubaStep = 6
return
}
if(MubaStep = 6)
{
WPD()
ReadAbilityNameValue()
if(AbilityName = "격투")
{
BWValue0 := AbilityValue
}
Sleep, 100
if(Gui_CheckUseMagic = 1)
{
RemoteM()
}
MubaStep = 1
return
}
}
}
if(Step = 10000)
{
internet := ConnectedToInternet()
if(internet = 0)
{
GuiControl, , Gui_NowState, 인터넷 끊김. 대기.
Sleep, 1000
}
if(internet = 1)
{
winhttp := ComObjCreate("Winhttp.WinHttpRequest.5.1")
winhttp.Open("Get","http://elancia.nexon.com/main/page/nx.aspx?url=home/index")
winhttp.Send("")
winHttp.WaitForResponse()
Content := winhttp.ResponseText
RegExMatch(Content,"style=\Ccolor:#60c722;\C>(.*?)</span>",Server)
if(Server1 = "정상")
{
GuiControl, , Gui_NowState, 일랜시아 게임 서버 정상. 5초 뒤 접속.
Sleep, 5000
Step = 0
return
}
if(Server1 != "정상")
{
GuiControl, , Gui_NowState, 일랜시아 홈페이지 서버 점검 중. 대기
Sleep, 1000
return
}
}
}
if(Step = 900)
{
Gui, Submit, Nohide
pName1 := Name1
pName2 := Name2
pName3 := Name3
pName4 := Name4
pName5 := Name5
pName6 := Name6
WinGet, pP1, PID, %pName1%
WinGet, pP2, PID, %pName2%
WinGet, pP3, PID, %pName3%
WinGet, pP4, PID, %pName4%
WinGet, pP5, PID, %pName5%
WinGet, pP6, PID, %pName6%
wtf := new _ClassMemory("ahk_pid " pP1, "", hProcessCopy)
ServerNsger := wtf.readString(0x0017E574, 40, "UTF-16", aOffsets*)
IfInString,ServerNsger,서버와의 연결이
{
GuiControl, , Gui_NowState, [포남] 파티 캐릭 재접속
Sleep, 1000
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP6%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP6%
Sleep, 500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP1%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP2%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP3%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP4%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP5%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP6%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP6%
step = 901
}
IfNotInString,ServerNsger,서버와의 연결이
{
step = 13
}
}
if(step = 901)
{
Gui, Submit, Nohide
WinGet, P1, PID, ahk_pid %pP1%
WinGet, P2, PID, ahk_pid %pP2%
WinGet, P3, PID, ahk_pid %pP3%
WinGet, P4, PID, ahk_pid %pP4%
WinGet, P5, PID, ahk_pid %pP5%
WinGet, P6, PID, ahk_pid %pP6%
Sleep, 2000
if(Gui_P1CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P1%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P1%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P1%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P1%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P1%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P1%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P1%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P1%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P1%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P1%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P1%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P1%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P1%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P1%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P1%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P1%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P1%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P1%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P1%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P1%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P1%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P1%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P1%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P1%
Sleep, 1500
if(Gui_P2CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P2%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P2%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P2%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P2%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P2%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P2%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P2%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P2%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P2%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P2%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P2%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P2%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P2%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P2%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P2%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P2%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P2%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P2%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P2%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P2%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P2%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P2%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P2%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P2%
Sleep, 1500
if(Gui_P3CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P3%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P3%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P3%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P3%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P3%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P3%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P3%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P3%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P3%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P3%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P3%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P3%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P3%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P3%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P3%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P3%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P3%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P3%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P3%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P3%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P3%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P3%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P3%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P3%
Sleep, 1500
if(Gui_P4CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P4%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P4%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P4%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P4%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P4%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P4%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P4%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P4%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P4%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P4%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P4%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P4%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P4%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P4%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P4%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P4%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P4%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P4%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P4%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P4%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P4%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P4%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P4%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P4%
Sleep, 1500
if(Gui_P5CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P5%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P5%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P5%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P5%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P5%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P5%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P5%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P5%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P5%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P5%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P5%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P5%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P5%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P5%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P5%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P5%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P5%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P5%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P5%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P5%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P5%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P5%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P5%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P5%
Sleep, 1500
if(Gui_P6CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P6%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P6%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P6%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P6%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P6%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P6%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P6%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P6%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P6%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P6%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P6%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P6%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P6%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P6%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P6%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P6%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P6%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P6%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P6%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P6%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P6%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P6%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P6%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P6%
Sleep, 10000
step = 13
}
if(Step = 910)
{
Gui, Submit, Nohide
pName1 := Name1
pName2 := Name2
pName3 := Name3
pName4 := Name4
pName5 := Name5
pName6 := Name6
WinGet, pP1, PID, %pName1%
WinGet, pP2, PID, %pName2%
WinGet, pP3, PID, %pName3%
WinGet, pP4, PID, %pName4%
WinGet, pP5, PID, %pName5%
WinGet, pP6, PID, %pName6%
wtf := new _ClassMemory("ahk_pid " pP1, "", hProcessCopy)
ServerNsger := wtf.readString(0x0017E574, 40, "UTF-16", aOffsets*)
IfInString,ServerNsger,서버와의 연결이
{
GuiControl, , Gui_NowState, [포남] 파티 캐릭 재접속
Sleep, 1000
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP6%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP6%
Sleep, 500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP1%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP1%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP2%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP2%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP3%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP3%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP4%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP4%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP5%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP5%
Sleep, 1500
PostMessage, 0x100, 13, 1835009, , ahk_pid %pP6%
PostMessage, 0x101, 13, 1835009, , ahk_pid %pP6%
step = 911
}
IfNotInString,ServerNsger,서버와의 연결이
{
step = 1004
}
}
if(step = 911)
{
Gui, Submit, Nohide
WinGet, P1, PID, ahk_pid %pP1%
WinGet, P2, PID, ahk_pid %pP2%
WinGet, P3, PID, ahk_pid %pP3%
WinGet, P4, PID, ahk_pid %pP4%
WinGet, P5, PID, ahk_pid %pP5%
WinGet, P6, PID, ahk_pid %pP6%
Sleep, 2000
if(Gui_P1CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P1%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P1%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P1%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P1%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P1%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P1%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P1%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P1%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P1%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P1%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P1%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P1%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P1%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P1%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P1%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P1%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P1%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P1%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P1%
}
if(Gui_P1CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P1%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P1%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P1%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P1%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P1%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P1%
Sleep, 1500
if(Gui_P2CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P2%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P2%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P2%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P2%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P2%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P2%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P2%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P2%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P2%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P2%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P2%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P2%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P2%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P2%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P2%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P2%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P2%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P2%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P2%
}
if(Gui_P2CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P2%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P2%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P2%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P2%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P2%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P2%
Sleep, 1500
if(Gui_P3CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P3%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P3%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P3%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P3%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P3%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P3%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P3%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P3%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P3%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P3%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P3%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P3%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P3%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P3%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P3%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P3%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P3%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P3%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P3%
}
if(Gui_P3CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P3%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P3%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P3%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P3%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P3%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P3%
Sleep, 1500
if(Gui_P4CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P4%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P4%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P4%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P4%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P4%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P4%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P4%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P4%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P4%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P4%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P4%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P4%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P4%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P4%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P4%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P4%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P4%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P4%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P4%
}
if(Gui_P4CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P4%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P4%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P4%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P4%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P4%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P4%
Sleep, 1500
if(Gui_P5CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P5%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P5%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P5%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P5%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P5%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P5%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P5%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P5%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P5%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P5%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P5%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P5%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P5%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P5%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P5%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P5%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P5%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P5%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P5%
}
if(Gui_P5CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P5%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P5%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P5%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P5%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P5%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P5%
Sleep, 1500
if(Gui_P6CharNumber = 1)
{
PostMessage, 0x200, 0, 13107662, , ahk_pid %P6%
PostMessage, 0x201, 1, 13107662, , ahk_pid %P6%
PostMessage, 0x202, 0, 13107662, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 2)
{
PostMessage, 0x200, 0, 14287311, , ahk_pid %P6%
PostMessage, 0x201, 1, 14287311, , ahk_pid %P6%
PostMessage, 0x202, 0, 14287311, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 3)
{
PostMessage, 0x200, 0, 15598030, , ahk_pid %P6%
PostMessage, 0x201, 1, 15598030, , ahk_pid %P6%
PostMessage, 0x202, 0, 15598030, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 4)
{
PostMessage, 0x200, 0, 16908752, , ahk_pid %P6%
PostMessage, 0x201, 1, 16908752, , ahk_pid %P6%
PostMessage, 0x202, 0, 16908752, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 5)
{
PostMessage, 0x200, 0, 18088402, , ahk_pid %P6%
PostMessage, 0x201, 1, 18088402, , ahk_pid %P6%
PostMessage, 0x202, 0, 18088402, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 6)
{
PostMessage, 0x200, 0, 19399121, , ahk_pid %P6%
PostMessage, 0x201, 1, 19399121, , ahk_pid %P6%
PostMessage, 0x202, 0, 19399121, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 7)
{
PostMessage, 0x200, 0, 20513232, , ahk_pid %P6%
PostMessage, 0x201, 1, 20513232, , ahk_pid %P6%
PostMessage, 0x202, 0, 20513232, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 8)
{
PostMessage, 0x200, 0, 21889488, , ahk_pid %P6%
PostMessage, 0x201, 1, 21889488, , ahk_pid %P6%
PostMessage, 0x202, 0, 21889488, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 9)
{
PostMessage, 0x200, 0, 23200209, , ahk_pid %P6%
PostMessage, 0x201, 1, 23200209, , ahk_pid %P6%
PostMessage, 0x202, 0, 23200209, , ahk_pid %P6%
}
if(Gui_P6CharNumber = 10)
{
PostMessage, 0x200, 0, 24314321, , ahk_pid %P6%
PostMessage, 0x201, 1, 24314321, , ahk_pid %P6%
PostMessage, 0x202, 0, 24314321, , ahk_pid %P6%
}
Sleep, 500
PostMessage, 0x200, 0, 22086223, , ahk_pid %P6%
PostMessage, 0x201, 1, 22086223, , ahk_pid %P6%
PostMessage, 0x202, 0, 22086223, , ahk_pid %P6%
Sleep, 10000
step = 1004
}
return
AttackCheck:
Gui, Submit, Nohide
if(Step >= 7 and Step < 10000)
{
Set_MoveSpeed()
}
if(Step = 27 or Step = 1026)
{
AttackLoopCount += 1
Check_Attack()
if(Attack = 0)
{
AttackCount += 1
}
if(Attack = 1 or Attack = 2)
{
AttackCount = 0
}
if(AttackLoopCount >= 10)
{
if(AttackCount > 5)
{
AttackLoopCount = 0
AttackCount = 0
if(HuntPlace = 1)
{
Step = 24
}
if(HuntPlace = 2)
{
Step = 1016
}
}
else
{
AttackLoopCount = 0
AttackCount = 0
}
}
}
return
GuiClose:
Gui, Submit, NoHide
IfWinExist,ahk_pid %jPID%
{
WinKill, ahk_pid %jPID%
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P1, %Name1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P2, %Name2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P3, %Name3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P4, %Name4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P5, %Name5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, P6, %Name6%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N1, %Gui_P1CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N2, %Gui_P2CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N3, %Gui_P3CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N4, %Gui_P4CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N5, %Gui_P5CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, N6, %Gui_P6CharNumber%
if(Gui_CheckUseHPExit = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPExit, 1
}
if(Gui_CheckUseHPExit = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPExit, 0
}
if(Gui_CheckUseMagic = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMagic, 1
}
if(Gui_CheckUseMagic = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMagic, 0
}
if(Gui_CheckUseParty = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseParty, 1
}
if(Gui_CheckUseParty = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseParty, 0
}
if(Gui_CheckUseHPPortal = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPPortal, 1
}
if(Gui_CheckUseHPPortal = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPPortal, 0
}
if(Gui_CheckUseHPLimited = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPLimited, 1
}
if(Gui_CheckUseHPLimited = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseHPLimited, 0
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPExit, %Gui_HPExit%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPPortal, %Gui_HPPortal%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, HPLimited, %Gui_HPLimited%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CrittHP, %Gui_CHP%
if(Gui_1Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 1
}
if(Gui_2Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 2
}
if(Gui_3Muba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 3
}
if(Gui_2ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 4
}
if(Gui_3ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 5
}
if(Gui_4ButMuba = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Muba, 6
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon1, %Gui_Weapon1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon2, %Gui_Weapon2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Weapon3, %Gui_Weapon3%
if(Gui_EvadeMand = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Evade, 1
}
if(Gui_EvadeMand = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Evade, 0
}
if(Gui_KON = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, KONOFF, 1
}
if(Gui_KOFF = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, KONOFF, 2
}
if(Gui_jjON = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, jjONOFF, 1
}
if(Gui_jjOFF = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, jjONOFF, 2
}
if(Gui_MoveLoute1 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 1
}
if(Gui_MoveLoute2 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 2
}
if(Gui_MoveLoute3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 3
}
if(Gui_MoveLoute4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Direct, 4
}
if(Gui_Ent = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 1
}
if(Gui_Rockey= 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 2
}
if(Gui_EntRockey= 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 3
}
if(Gui_Mand = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 4
}
if(Gui_AllMobAND = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 5
}
if(Gui_AllMobOR = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 6
}
if(Gui_MobMagic = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Monster, 7
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, AllMobLimit, %Gui_AllMobLimit%
if(Gui_HuntAuto = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 1
}
if(Gui_HuntPonam = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 2
}
if(Gui_HuntPobuk = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Place, 3
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit0, %Gui_LimitAbility0%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit1, %Gui_LimitAbility1%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit2, %Gui_LimitAbility2%
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Limit3, %Gui_LimitAbility3%
if(Gui_PartyOn = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Party, 1
}
if(Gui_PartyOff = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Party, 2
}
if(Gui_Grade = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Grade, 1
}
if(Gui_Grade = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Grade, 0
}
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, loady, 0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, RasCount, %Gui_RasCount%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CharNumber, %Gui_CharNumber%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, MNS, %Gui_MagicNStack%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Server, %Gui_Server%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, ID, %Gui_NexonID%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, Pass
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, StartTime
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, CFH
if(Gui_WeaponCheck1 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC1, 1
}
if(Gui_WeaponCheck1 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC1, 0
}
if(Gui_WeaponCheck2 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC2, 1
}
if(Gui_WeaponCheck2 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC2, 0
}
if(Gui_WeaponCheck3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC3, 1
}
if(Gui_WeaponCheck3 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC3, 0
}
if(Gui_WeaponCheck4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC4, 1
}
if(Gui_WeaponCheck4 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC4, 0
}
if(Gui_WeaponCheck5 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC5, 1
}
if(Gui_WeaponCheck5 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC5, 0
}
if(Gui_WeaponCheck6 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC6, 1
}
if(Gui_WeaponCheck6 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC6, 0
}
if(Gui_WeaponCheck7 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC7, 1
}
if(Gui_WeaponCheck7 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC7, 0
}
if(Gui_WeaponCheck8 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC8, 1
}
if(Gui_WeaponCheck8 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC8, 0
}
if(Gui_WeaponCheck9 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC9, 1
}
if(Gui_WeaponCheck9 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC9, 0
}
if(Gui_WeaponCheck10 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC10, 1
}
if(Gui_WeaponCheck10 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC10, 0
}
if(Gui_WeaponCheck11 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC11, 1
}
if(Gui_WeaponCheck11 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC11, 0
}
if(Gui_WeaponCheck12 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC12, 1
}
if(Gui_WeaponCheck12 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC12, 0
}
if(Gui_WeaponCheck13 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC13, 1
}
if(Gui_WeaponCheck13 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC13, 0
}
if(Gui_WeaponCheck14 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC14, 1
}
if(Gui_WeaponCheck14 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 0
}
if(Gui_WeaponCheck15 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 1
}
if(Gui_WeaponCheck15 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC15, 0
}
if(Gui_WeaponCheck16 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC16, 1
}
if(Gui_WeaponCheck16 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC16, 0
}
if(Gui_WeaponCheck17 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC17, 1
}
if(Gui_WeaponCheck17 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC17, 0
}
if(Gui_WeaponCheck18 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC18, 1
}
if(Gui_WeaponCheck18 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC18, 0
}
if(Gui_WeaponCheck19 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC19, 1
}
if(Gui_WeaponCheck19 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC19, 0
}
if(Gui_WeaponCheck20 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC20, 1
}
if(Gui_WeaponCheck20 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseWC20, 0
}
if(Gui_MagicCheck3 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC3, 1
}
if(Gui_MagicCheck3 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC3, 0
}
if(Gui_MagicCheck4 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC4, 1
}
if(Gui_MagicCheck4 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC4, 0
}
if(Gui_MagicCheck5 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC5, 1
}
if(Gui_MagicCheck5 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC5, 0
}
if(Gui_MagicCheck6 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC6, 1
}
if(Gui_MagicCheck6 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC6, 0
}
if(Gui_MagicCheck7 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC7, 1
}
if(Gui_MagicCheck7 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC7, 0
}
if(Gui_MagicCheck8 = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC8, 1
}
if(Gui_MagicCheck8 = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, UseMC8, 0
}
if(Gui_relogerror = 1)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, relog, 1
}
if(Gui_relogerror = 0)
{
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Nexon\MRMChezam, relog, 0
}
Gui, submit, nohide
Gui, listview, incinerateitemPN
FileDelete, C:\Nexon\Elancia\incipn.ini
save := LV_GetCount()
loop, %save%{
lv_gettext(savefile1,a_index)
FileAppend, %savefile1%`n, C:\Nexon\Elancia\incipn.ini
}
Gui, submit, nohide
Gui, listview, incinerateitemPB
FileDelete, C:\Nexon\Elancia\incipb.ini
save := LV_GetCount()
loop, %save%{
lv_gettext(savefile1,a_index)
FileAppend, %savefile1%`n, C:\Nexon\Elancia\incipb.ini
}
WinKill, ahk_exe MRMSPH.exe
WinKill, ahk_exe helan.exe
ExitApp
return
IME_CHECK(WinTitle)
{
WinGet, hWnd, ID, %WinTitle%
Return, Send_ImeControl(ImmGetDefaultIMEWnd(hWnd),0x005,"")
}
Send_ImeControl(DefaultIMEWnd, wParam, lParam)
{
DetectSave := A_DetectHiddenWindows
DetectHiddenWindows, ON
SendMessage, 0x283, wParam, lParam, , ahk_id %DefaultIMEWnd%
if (DetectSave <> A_DetectHiddenWindows)
DetectHiddenWindows, %DetectSave%
Return, ErrorLevel
}
ImmGetDefaultIMEWnd(hWnd)
{
Return, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)
}
ChangeDisplaySettings( cD, sW, sH, rR )
{
VarSetCapacity(dM,156,0), NumPut(156,dM,36)
DllCall( "EnumDisplaySettingsA", UInt,0, UInt,-1, UInt,&dM ), NumPut(0x5c0000,dM,40)
NumPut(cD,dM,104),  NumPut(sW,dM,108),  NumPut(sH,dM,112),  NumPut(rR,dM,120)
Return, DllCall( "ChangeDisplaySettingsA", UInt,&dM, UInt,0 )
}
FormatSeconds(NumberOfSeconds)
{
time = 19990101
time += %NumberOfSeconds%, seconds
FormatTime, mmss, %time%, mm:ss
SetFormat, float, 2.0
Return, NumberOfSeconds//3600 ":" mmss
}
ConnectedToInternet(flag=0x40)
{
Return, DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag,"Int",0)
}
Loading()
{
Sleep, 500
Loop,
{
if(pwb.readyState() = 4)
{
Sleep, 500
break
}
}
}
Gui_Enable()
{
GuiControlGet, Gui_CheckUseHPExit
GuiControlGet, Gui_CheckUseHPPortal
GuiControlGet, Gui_1Muba
GuiControlGet, Gui_2Muba
GuiControlGet, Gui_3Muba
GuiControlGet, Gui_2ButMuba
GuiControlGet, Gui_3ButMuba
GuiControlGet, Gui_4ButMuba
GuiControlGet, Gui_Mand
GuiControlGet, Gui_AllMobAND
GuiControlGet, Gui_AllMobOR
GuiControlGet, Gui_MobMagic
GuiControl, Enable, Gui_NexonID
GuiControl, Enable, Gui_NexonPassWord
GuiControl, Enable, Gui_Server
GuiControl, Enable, Gui_CharNumber
GuiControl, Enable, Gui_CheckUseHPExit
GuiControl, Enable, Gui_CheckUseHPPortal
GuiControl, Enable, Gui_CheckUseHPLimited
GuiControl, Enable, Gui_jjON
GuiControl, Enable, Gui_jjOFF
if(Gui_CheckUseHPExit = 1)
{
GuiControl, Enable, Gui_HPExit
}
if(Gui_CheckUseHPPortal = 1)
{
GuiControl, Enable, Gui_HPPortal
}
if(Gui_CheckUseHPLimited = 1)
{
GuiControl, Enable, Gui_HPLimited
}
GuiControl, Enable, Gui_1Muba
GuiControl, Enable, Gui_2Muba
GuiControl, Enable, Gui_3Muba
GuiControl, Enable, Gui_2ButMuba
GuiControl, Enable, Gui_3ButMuba
GuiControl, Enable, Gui_4ButMuba
if(Gui_1Muba = 1 or Gui_2ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
if(Gui_2ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
}
GuiControl, Enable, Gui_LimitAbility1
}
if(Gui_2Muba = 1 or Gui_3ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
if(Gui_3ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
}
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
}
if(Gui_3Muba = 1 or Gui_4ButMuba = 1)
{
GuiControl, Enable, Gui_Weapon1
GuiControl, Enable, Gui_Weapon2
GuiControl, Enable, Gui_Weapon3
if(Gui_4ButMuba = 1)
{
GuiControl, Enable, Gui_LimitAbility0
}
GuiControl, Enable, Gui_LimitAbility1
GuiControl, Enable, Gui_LimitAbility2
GuiControl, Enable, Gui_LimitAbility3
}
GuiControl, Enable, Gui_RasCount
if(Gui_Mand = 0 and Gui_AllMobAND = 0 and Gui_AllMobOR = 0 and Gui_MobMagic =0)
{
GuiControl, Enable, Gui_EvadeMand
}
if(Gui_Mand = 1 or Gui_AllMobAND = 1 or Gui_AllMobOR = 1 or Gui_MobMaigc =1)
{
GuiControl, Enable, Gui_AllMobLimit
}
GuiControl, Enable, Gui_MoveLoute1
GuiControl, Enable, Gui_MoveLoute2
GuiControl, Enable, Gui_MoveLoute3
GuiControl, Enable, Gui_MoveLoute4
GuiControl, Enable, Gui_Ent
GuiControl, Enable, Gui_Rockey
GuiControl, Enable, Gui_EntRockey
GuiControl, Enable, Gui_Mand
GuiControl, Enable, Gui_AllMobAND
GuiControl, Enable, Gui_AllMobOR
GuiControl, Enable, Gui_MobMagic
GuiControl, Enable, Gui_PartyOn
GuiControl, Enable, Gui_PartyOff
GuiControl, Enable, Gui_Grade
GuiControl, Enable, Gui_StartButton
GuiControl, Enable, Gui_WindowSettingButton
GuiControl, Enable, Gui_Agree
}
PostMove(MouseX,MouseY)
{
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos%, , ahk_pid %jPID%
}
PostClick(MouseX,MouseY)
{
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x201, 1, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x202, 0, %MousePos%, , ahk_pid %jPID%
}
PostDClick(MouseX,MouseY)
{
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x203, 0, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x202, 0, %MousePos%, , ahk_pid %jPID%
}
PostRClick(MouseX,MouseY)
{
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x204, 1, %MousePos%, , ahk_pid %jPID%
PostMessage, 0x205, 0, %MousePos%, , ahk_pid %jPID%
}
OpenMap()
{
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 86, 3014657, , ahk_pid %jPID%
PostMessage, 0x101, 86, 3014657, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
}
AltR()
{
PostMessage, 0x100, 18, 540540929, , ahk_pid %jPID%
PostMessage, 0x100, 82, 1245185, , ahk_pid %jPID%
PostMessage, 0x101, 82, 1245185, , ahk_pid %jPID%
PostMessage, 0x101, 18, 540540929, , ahk_pid %jPID%
}
Set_MoveSpeed()
{
value := jelan.write(0x0058DAD4, 750, "UInt", 0x178, 0x9C)
value := jelan.write(0x0058DAD4, 750, "UInt", 0x178, 0x98)
}
Check_Moving()
{
Moving := jelan.read(0x0058EB1C, "UInt", 0x174)
}
Check_OID_Sex()
{
CCD := ReadMemory(0x00584C2C)
}
Check_OID()
{
CCD := jelan.read(0x00584C2C, "UInt", aOffsets*)
}
Check_State()
{
State := jelan.read(0x0058EB98, "UInt", aOffsets*)
if(State != 0)
{
State = 1
}
}
Check_StatePos()
{
StatePosX := jelan.read(0x0058EB48, "UInt", 0x44)
StatePosY := jelan.read(0x0058EB48, "UInt", 0x48)
}
Check_Mount()
{
Mount := jelan.read(0x0058DAD4, "UInt", 0x22C)
}
Check_Shield()
{
Shield := jelan.read(0x0058DAD4, "UInt", 0x1FC)
}
Check_Inven()
{
Inven := jelan.read(0x0058EB2C, "UInt", aOffsets*)
if(Inven != 0)
{
Inven = 1
}
}
Check_Shop()
{
Buy := jelan.read(0x0058EBB9, "UInt", aOffsets*)
if(Buy != 0)
{
Buy = 1
}
Repair := jelan.read(0x0058F0C0, "UInt", aOffsets*)
if(Repair != 0)
{
Repair = 1
}
}
Check_Ras()
{
Ras := jelan.read(0x0058F0CC, "UInt", aOffsets*)
if(Ras != 0)
{
Ras = 1
}
SelectRas := jelan.read(0x0058F100, "UInt", aOffsets*)
if(SelectRas != 0)
{
SelectRas = 1
}
}
Check_Map()
{
Map := jelan.read(0x0058EB6C, "UInt", aOffsets*)
MapSize := jelan.read(0x0058DAD0, "UInt", 0xC, 0x10, 0x8, 0x264)
if(Map != 0)
{
Map = 1
}
}
Check_SAbilityN()
{
Slot1AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x4, 0x8, 0x4)
Slot2AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x8, 0x8, 0x4)
Slot3AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0xC, 0x8, 0x4)
Slot4AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x10, 0x8, 0x4)
Slot5AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x14, 0x8, 0x4)
Slot6AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x18, 0x8, 0x4)
Slot7AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x1C, 0x8, 0x4)
Slot8AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x20, 0x8, 0x4)
Slot9AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x24, 0x8, 0x4)
Slot10AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x28, 0x8, 0x4)
Slot11AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x2C, 0x8, 0x4)
Slot12AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x30, 0x8, 0x4)
Slot13AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x34, 0x8, 0x4)
Slot14AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x38, 0x8, 0x4)
Slot15AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x3C, 0x8, 0x4)
Slot16AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x40, 0x8, 0x4)
Slot17AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x44, 0x8, 0x4)
Slot18AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x48, 0x8, 0x4)
Slot19AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x4C, 0x8, 0x4)
Slot20AN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC6, 0x8, 0x50, 0x8, 0x4)
}
Check_SMagicN()
{
Slot3MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0xC, 0x8, 0xC)
Slot4MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0x10, 0x8, 0xC)
Slot5MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0x14, 0x8, 0xC)
Slot6MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0x18, 0x8, 0xC)
Slot7MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0x1C, 0x8, 0xC)
Slot8MN := jelan.readString(0x0058DAD4, 22, "UTF-16", 0x178, 0xC2, 0x8, 0x20, 0x8, 0xC)
}
Check_SMagic()
{
Slot3Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0xC, 0x8, 0x42C)
Slot4Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0x10, 0x8, 0x42C)
Slot5Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0x14, 0x8, 0x42C)
Slot6Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0x18, 0x8, 0x42C)
Slot7Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0x1C, 0x8, 0x42C)
Slot8Magic := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC2, 0x8, 0x20, 0x8, 0x42C)
}
Check_SAbility()
{
Slot1Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x4, 0x8, 0x208)
Slot2Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x8, 0x8, 0x208)
Slot3Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0xC, 0x8, 0x208)
Slot4Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x10, 0x8, 0x208)
Slot5Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x14, 0x8, 0x208)
Slot6Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x18, 0x8, 0x208)
Slot7Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x1C, 0x8, 0x208)
Slot8Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x20, 0x8, 0x208)
Slot9Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x24, 0x8, 0x208)
Slot10Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x28, 0x8, 0x208)
Slot11Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x2C, 0x8, 0x208)
Slot12Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x30, 0x8, 0x208)
Slot13Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x34, 0x8, 0x208)
Slot14Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x38, 0x8, 0x208)
Slot15Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x3C, 0x8, 0x208)
Slot16Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x40, 0x8, 0x208)
Slot17Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x44, 0x8, 0x208)
Slot18Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x48, 0x8, 0x208)
Slot19Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x4C, 0x8, 0x208)
Slot20Ability := jelan.read(0x0058DAD4, "UInt", 0x178, 0xC6, 0x8, 0x50, 0x8, 0x208)
}
Check_Weapon()
{
Weapon := jelan.read(0x0058DAD4, "UInt", 0x121)
}
Check_Attack()
{
Attack := jelan.read(0x0058DAD4, "UInt", 0x178, 0xEB)
}
Check_Chat()
{
Chat := jelan.read(0x0058DAD4, "UInt", 0x1AC)
}
Check_NPCMenu()
{
NPCMenu := jelan.read(0x0058F0A4, "UInt", aOffsets*)
if(NPCMenu != 0)
{
NPCMenu = 1
}
}
Check_NPCMenuPos()
{
NPCMenuPosX := jelan.read(0x0058F0A4, "UShort", 0x9A)
NPCMenuPosY := jelan.read(0x0058F0A4, "UShort", 0x9E)
NPCMenuBuyPosX := NPCMenuPosX + 10
NPCMenuBuyPosY := NPCMenuPosY + 15
NPCMenuRepairPosX := NPCMenuPosX + 60
NPCMenuRepairPosY := NPCMenuPosY + 15
}
Crit_HM()
{
value := jelan.write(0x00527A40, CritHP, "UInt")
}
Stack_MN()
{
GuiControlGet, RMNN, , Gui_MagicNStack
value := jelan.write(0x00527ABB, RMNN, "UInt")
}
Check_NPCMsg()
{
NPCMsg := jelan.readString(0x0017E4EC, 100, "UTF-16")
}
Write_NPCMsg()
{
WriteNPCMsg := jelan.writeString(0x0017E4EC, "", "UTF-16")
}
PickUp_itemsetPS()
{
value := jelan.writeString(0x00590A00, "생명의콩", "UTF-16")
}
PickUp_itemsetPN()
{
value := jelan.writeString(0x00590A00, "빛나는가루", "UTF-16")
}
incinerate_item()
{
value := jelan.writeString(0x005909C0, inciItem , "UTF-16")
}
Check_FormNumber()
{
FormNumber := jelan.read(0x0058DAD0, "UInt", 0xC, 0x10, 0x8, 0xA0)
}
Move_Inven()
{
value := jelan.write(0x0058EB48, 306, "UInt", 0x5C)
value := jelan.write(0x0058EB48, 534, "UInt", 0x60)
}
Move_State()
{
value := jelan.write(0x0058EB48, 565, "UInt", 0x44)
value := jelan.write(0x0058EB48, 655, "UInt", 0x48)
}
Move_StateForMount()
{
value := jelan.write(0x0058EB48, 130, "UInt", 0x44)
value := jelan.write(0x0058EB48, 174, "UInt", 0x48)
}
Move_Map()
{
value := jelan.write(0x0058EB48, 400, "UInt", 0x80)
value := jelan.write(0x0058EB48, 300, "UInt", 0x84)
}
Move_Buy()
{
value := jelan.write(0x0058EB48, 233, "UInt", 0x8C)
value := jelan.write(0x0058EB48, 173, "UInt", 0x90)
}
Move_Repair()
{
value := jelan.write(0x0058EB48, 230, "UInt", 0xA4)
value := jelan.write(0x0058EB48, 170, "UInt", 0xA8)
}
Move_NPCTalkForm()
{
value := jelan.write(0x0058EB48, 135, "UInt", 0xC8)
value := jelan.write(0x0058EB48, 69, "UInt", 0xCC)
}
Get_Pos()
{
PosX := jelan.read(0x0058DAD4, "UInt", 0x10)
PosY := jelan.read(0x0058DAD4, "UInt", 0x14)
}
Get_MovePos()
{
MovePosX := jelan.read(0x0058EA10, "UInt", aOffsets*)
MovePosY := jelan.read(0x0058EA14, "UInt", aOffsets*)
}
Get_HP()
{
NowHP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x5B)
MaxHP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x1F)
HPPercent := Floor((NowHP / MaxHP) * 100)
}
Get_MP()
{
NowMP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x5F)
MaxMP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x23)
}
Get_FP()
{
NowFP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x63)
MaxFP := jelan.read(0x0058DAD4, "UInt", 0x178, 0x27)
FPPercent := Floor((NowFP / MaxFP) * 100)
}
Get_Gold()
{
Gold := jelan.read(0x0058DAD4, "UInt", 0x178, 0x6F)
}
Get_AGI()
{
AGI := jelan.read(0x0058DAD4, "UInt", 0x178, 0x3F)
}
Get_MsgM()
{
SetFormat, integer, H
jelanCoreMM := jelan.getModuleBaseAddress("jelancia_core.dll")
MsgMacro := jelanCoreMM + 0x000764EC
SetFormat, integer, D
MsgM := jelan.read(MsgMacro, "UChar", aOffsets*)
if(MsgM != 0)
{
Send, !2
}
}
Get_Perfect()
{
SetFormat, integer, H
jelanCorePF := jelan.getModuleBaseAddress("jelancia_core.dll")
PFOF := jelanCorePF + 0x000764EE
SetFormat, integer, D
PFOFS := jelan.read(PFOF, "UChar", aOffsets*)
if(PFOFS != 0)
{
Send, !1
}
}
Get_Location()
{
SetFormat, integer, H
jelanCoreAdd := jelan.getModuleBaseAddress("jelancia_core.dll")
LocationPointerAdd := jelanCoreAdd + 0x00076508
SetFormat, integer, D
Location := jelan.readString(LocationPointerAdd, 50, "UTF-16",0)
}
Get_NowDate()
{
TempMont := A_MM
if(TempMont < 10)
{
StringTrimLeft, TempMont, TempMont, 1
}
TempDay := A_DD
if(TempDay < 10)
{
StringTrimLeft, TempDay, TempDay, 1
}
TempWDay := A_WDay
if(TempWDay = 1)
{
TempWDay = 일
}
if(TempWDay = 2)
{
TempWDay = 월
}
if(TempWDay = 3)
{
TempWDay = 화
}
if(TempWDay = 4)
{
TempWDay = 수
}
if(TempWDay = 5)
{
TempWDay = 목
}
if(TempWDay = 6)
{
TempWDay = 금
}
if(TempWDay = 7)
{
TempWDay = 토
}
NowDate = %TempMont%/%TempDay%(%TempWDay%)
}
tac109()
{
RunWait, %comspec% /c wmic bios get serialnumber > bal.txt
Loop,Read, bal.txt
{
ifinstring, A_LoopReadLine,VMware-
{
lov = %A_LoopReadLine%
break
}
}
}
CharMovePonam(Loute1,Loute2,Loute3,Loute4)
{
if(Loute1 = 1)
{
Gosub, 감흥
{
if(MapNumber = 1)
{
PostClick(402,140)
}
if(MapNumber = 2)
{
PostClick(402,170)
}
if(MapNumber = 3)
{
PostClick(402,200)
}
if(MapNumber = 4)
{
PostClick(442,200)
}
if(MapNumber = 5)
{
PostClick(482,200)
}
if(MapNumber = 6)
{
PostClick(462,170)
}
if(MapNumber = 7)
{
PostClick(462,140)
}
if(MapNumber = 8)
{
PostClick(502,140)
}
if(MapNumber = 9)
{
PostClick(502,170)
}
if(MapNumber = 10)
{
PostClick(536,168)
}
if(MapNumber = 11)
{
PostClick(564,140)
}
if(MapNumber = 12)
{
PostClick(586,168)
}
if(MapNumber = 13)
{
PostClick(562,178)
}
if(MapNumber = 14)
{
PostClick(588,198)
}
if(MapNumber = 15)
{
PostClick(590,232)
}
if(MapNumber = 16)
{
PostClick(590,262)
}
if(MapNumber = 17)
{
PostClick(590,292)
}
if(MapNumber = 18)
{
PostClick(590,322)
}
if(MapNumber = 19)
{
PostClick(590,352)
}
if(MapNumber = 20)
{
PostClick(590,384)
}
if(MapNumber = 21)
{
PostClick(590,414)
}
if(MapNumber = 22)
{
PostClick(590,446)
}
if(MapNumber = 23)
{
PostClick(550,446)
}
if(MapNumber = 24)
{
PostClick(550,416)
}
if(MapNumber = 25)
{
PostClick(550,386)
}
if(MapNumber = 26)
{
PostClick(550,356)
}
if(MapNumber = 27)
{
PostClick(550,326)
}
if(MapNumber = 28)
{
PostClick(550,296)
}
if(MapNumber = 29)
{
PostClick(550,260)
}
if(MapNumber = 30)
{
PostClick(550,222)
}
if(MapNumber = 31)
{
PostClick(540,200)
}
if(MapNumber = 32)
{
PostClick(512,200)
}
if(MapNumber = 33)
{
PostClick(512,230)
}
if(MapNumber = 34)
{
PostClick(512,260)
}
if(MapNumber = 35)
{
PostClick(512,290)
}
if(MapNumber = 36)
{
PostClick(512,326)
}
if(MapNumber = 37)
{
PostClick(512,356)
}
if(MapNumber = 38)
{
PostClick(512,386)
}
if(MapNumber = 39)
{
PostClick(512,416)
}
if(MapNumber = 40)
{
PostClick(512,447)
}
if(MapNumber = 41)
{
PostClick(474,414)
}
if(MapNumber = 42)
{
PostClick(474,382)
}
if(MapNumber = 43)
{
PostClick(474,352)
}
if(MapNumber = 44)
{
PostClick(474,322)
}
if(MapNumber = 45)
{
PostClick(474,288)
}
if(MapNumber = 46)
{
PostClick(474,258)
}
if(MapNumber = 47)
{
PostClick(474,228)
}
if(MapNumber = 48)
{
PostClick(434,228)
}
if(MapNumber = 49)
{
PostClick(434,258)
}
if(MapNumber = 50)
{
PostClick(434,288)
}
if(MapNumber = 51)
{
PostClick(434,320)
}
if(MapNumber = 52)
{
PostClick(434,350)
}
if(MapNumber = 53)
{
PostClick(434,382)
}
if(MapNumber = 54)
{
PostClick(394,382)
}
if(MapNumber = 55)
{
PostClick(398,350)
}
if(MapNumber = 56)
{
PostClick(396,318)
}
if(MapNumber = 57)
{
PostClick(396,282)
}
if(MapNumber = 58)
{
PostClick(396,252)
}
if(MapNumber = 59)
{
PostClick(396,222)
}
if(MapNumber = 60)
{
PostClick(356,222)
}
if(MapNumber = 61)
{
PostClick(356,252)
}
if(MapNumber = 62)
{
PostClick(356,282)
}
if(MapNumber = 63)
{
PostClick(356,312)
}
if(MapNumber = 64)
{
PostClick(356,342)
}
if(MapNumber = 65)
{
PostClick(356,372)
}
if(MapNumber = 66)
{
PostClick(356,402)
}
if(MapNumber = 67)
{
PostClick(356,438)
}
if(MapNumber = 68)
{
PostClick(328,414)
}
if(MapNumber = 69)
{
PostClick(316,388)
}
if(MapNumber = 70)
{
PostClick(276,388)
}
if(MapNumber = 71)
{
PostClick(276,358)
}
if(MapNumber = 72)
{
PostClick(316,358)
}
if(MapNumber = 73)
{
PostClick(316,328)
}
if(MapNumber = 74)
{
PostClick(276,328)
}
if(MapNumber = 75)
{
PostClick(276,298)
}
if(MapNumber = 76)
{
PostClick(316,298)
}
if(MapNumber = 77)
{
PostClick(316,268)
}
if(MapNumber = 78)
{
PostClick(276,268)
}
if(MapNumber = 79)
{
PostClick(276,238)
}
if(MapNumber = 80)
{
PostClick(316,238)
}
if(MapNumber = 81)
{
PostClick(316,208)
}
if(MapNumber = 82)
{
PostClick(280,206)
}
if(MapNumber = 83)
{
PostClick(234,178)
}
if(MapNumber = 84)
{
PostClick(232,142)
}
if(MapNumber = 85)
{
PostClick(192,144)
}
if(MapNumber = 86)
{
PostClick(192,184)
}
if(MapNumber = 87)
{
PostClick(204,234)
}
if(MapNumber = 88)
{
PostClick(204,274)
}
if(MapNumber = 89)
{
PostClick(204,314)
}
if(MapNumber = 90)
{
PostClick(204,354)
}
if(MapNumber = 91)
{
PostClick(204,396)
}
if(MapNumber = 92)
{
PostClick(206,436)
}
if(MapNumber = 93)
{
PostClick(244,450)
}
if(MapNumber = 94)
{
PostClick(274,450)
}
if(MapNumber = 95)
{
PostClick(234,422)
}
if(MapNumber = 96)
{
PostClick(204,396)
}
if(MapNumber = 97)
{
PostClick(204,354)
}
if(MapNumber = 98)
{
PostClick(204,314)
}
if(MapNumber = 99)
{
PostClick(204,274)
}
if(MapNumber = 100)
{
PostClick(204,234)
}
if(MapNumber = 101)
{
PostClick(192,184)
}
if(MapNumber = 102)
{
PostClick(192,144)
}
if(MapNumber = 103)
{
PostClick(232,142)
}
if(MapNumber = 104)
{
PostClick(234,178)
}
if(MapNumber = 105)
{
PostClick(280,206)
}
if(MapNumber = 106)
{
PostClick(280,176)
}
if(MapNumber = 107)
{
PostClick(316,178)
}
if(MapNumber = 108)
{
PostClick(314,150)
}
if(MapNumber = 109)
{
PostClick(342,148)
}
if(MapNumber = 110)
{
PostClick(358,186)
}
if(MapNumber = 111)
{
PostClick(402,200)
}
if(MapNumber = 112)
{
PostClick(402,170)
}
if(MapNumber = 113)
{
PostClick(402,140)
}
if(MapNumber = 114)
{
PostClick(402,170)
}
if(MapNumber = 115)
{
PostClick(402,200)
}
if(MapNumber = 116)
{
PostClick(442,200)
}
if(MapNumber = 117)
{
PostClick(482,200)
}
if(MapNumber = 118)
{
PostClick(462,170)
}
if(MapNumber = 119)
{
PostClick(462,140)
}
if(MapNumber = 120)
{
PostClick(502,140)
}
if(MapNumber = 121)
{
PostClick(502,170)
}
if(MapNumber = 122)
{
PostClick(536,168)
}
if(MapNumber = 123)
{
PostClick(564,140)
}
if(MapNumber = 124)
{
PostClick(586,168)
}
if(MapNumber = 125)
{
PostClick(562,178)
}
if(MapNumber = 126)
{
PostClick(588,198)
}
if(MapNumber = 127)
{
PostClick(590,232)
}
if(MapNumber = 128)
{
PostClick(590,262)
}
if(MapNumber = 129)
{
PostClick(590,292)
}
if(MapNumber = 130)
{
PostClick(590,322)
}
if(MapNumber = 131)
{
PostClick(590,352)
}
if(MapNumber = 132)
{
PostClick(590,384)
}
if(MapNumber = 133)
{
PostClick(590,414)
}
if(MapNumber = 134)
{
PostClick(590,446)
}
if(MapNumber = 135)
{
PostClick(550,446)
}
if(MapNumber = 136)
{
PostClick(550,416)
}
if(MapNumber = 137)
{
PostClick(550,386)
}
if(MapNumber = 138)
{
PostClick(550,356)
}
if(MapNumber = 139)
{
PostClick(550,326)
}
if(MapNumber = 140)
{
PostClick(550,296)
}
if(MapNumber = 141)
{
PostClick(550,260)
}
if(MapNumber = 142)
{
PostClick(550,222)
}
if(MapNumber = 143)
{
PostClick(540,200)
}
if(MapNumber = 144)
{
PostClick(512,200)
}
if(MapNumber = 145)
{
PostClick(512,230)
}
if(MapNumber = 146)
{
PostClick(512,260)
}
if(MapNumber = 147)
{
PostClick(512,290)
}
if(MapNumber = 148)
{
PostClick(512,326)
}
if(MapNumber = 149)
{
PostClick(512,356)
}
if(MapNumber = 150)
{
PostClick(512,386)
}
if(MapNumber = 151)
{
PostClick(512,416)
}
if(MapNumber = 152)
{
PostClick(512,447)
}
if(MapNumber = 153)
{
PostClick(474,414)
}
if(MapNumber = 154)
{
PostClick(474,382)
}
if(MapNumber = 155)
{
PostClick(474,352)
}
if(MapNumber = 156)
{
PostClick(474,322)
}
if(MapNumber = 157)
{
PostClick(474,288)
}
if(MapNumber = 158)
{
PostClick(474,258)
}
if(MapNumber = 159)
{
PostClick(474,228)
}
if(MapNumber = 160)
{
PostClick(434,228)
}
if(MapNumber = 161)
{
PostClick(434,258)
}
if(MapNumber = 162)
{
PostClick(434,288)
}
if(MapNumber = 163)
{
PostClick(434,320)
}
if(MapNumber = 164)
{
PostClick(434,350)
}
if(MapNumber = 165)
{
PostClick(434,382)
}
if(MapNumber = 166)
{
PostClick(394,382)
}
if(MapNumber = 167)
{
PostClick(398,350)
}
if(MapNumber = 168)
{
PostClick(396,318)
}
if(MapNumber = 169)
{
PostClick(396,282)
}
if(MapNumber = 170)
{
PostClick(396,252)
}
if(MapNumber = 171)
{
PostClick(396,222)
}
if(MapNumber = 172)
{
PostClick(356,222)
}
if(MapNumber = 173)
{
PostClick(356,252)
}
if(MapNumber = 174)
{
PostClick(356,282)
}
if(MapNumber = 175)
{
PostClick(356,312)
}
if(MapNumber = 176)
{
PostClick(356,342)
}
if(MapNumber = 177)
{
PostClick(356,372)
}
if(MapNumber = 178)
{
PostClick(356,402)
}
if(MapNumber = 179)
{
PostClick(356,438)
}
if(MapNumber = 180)
{
PostClick(328,414)
}
if(MapNumber = 181)
{
PostClick(316,388)
}
if(MapNumber = 182)
{
PostClick(276,388)
}
if(MapNumber = 183)
{
PostClick(276,358)
}
if(MapNumber = 184)
{
PostClick(316,358)
}
if(MapNumber = 185)
{
PostClick(316,328)
}
if(MapNumber = 186)
{
PostClick(276,328)
}
if(MapNumber = 187)
{
PostClick(276,298)
}
if(MapNumber = 188)
{
PostClick(316,298)
}
if(MapNumber = 189)
{
PostClick(316,268)
}
if(MapNumber = 190)
{
PostClick(276,268)
}
if(MapNumber = 191)
{
PostClick(276,238)
}
if(MapNumber = 192)
{
PostClick(316,238)
}
if(MapNumber = 193)
{
PostClick(316,208)
}
if(MapNumber = 194)
{
PostClick(280,206)
}
if(MapNumber = 195)
{
PostClick(280,176)
}
if(MapNumber = 196)
{
PostClick(316,178)
}
if(MapNumber = 197)
{
PostClick(314,150)
}
if(MapNumber = 198)
{
PostClick(342,148)
}
if(MapNumber = 199)
{
PostClick(358,186)
}
if(MapNumber = 200)
{
PostClick(402,200)
}
if(MapNumber = 201)
{
PostClick(402,170)
MapNumber = 112
}
}
}
if(Loute2 = 1)
{
Gosub, 감흥
{
if(MapNumber = 1)
{
PostClick(402,140)
}
if(MapNumber = 2)
{
PostClick(402,170)
}
if(MapNumber = 3)
{
PostClick(402,200)
}
if(MapNumber = 4)
{
PostClick(358,186)
}
if(MapNumber = 5)
{
PostClick(342,148)
}
if(MapNumber = 6)
{
PostClick(314,150)
}
if(MapNumber = 7)
{
PostClick(316,178)
}
if(MapNumber = 8)
{
PostClick(280,176)
}
if(MapNumber = 9)
{
PostClick(280,206)
}
if(MapNumber = 10)
{
PostClick(234,178)
}
if(MapNumber = 11)
{
PostClick(232,142)
}
if(MapNumber = 12)
{
PostClick(192,144)
}
if(MapNumber = 13)
{
PostClick(192,184)
}
if(MapNumber = 14)
{
PostClick(204,234)
}
if(MapNumber = 15)
{
PostClick(204,274)
}
if(MapNumber = 16)
{
PostClick(204,314)
}
if(MapNumber = 17)
{
PostClick(204,354)
}
if(MapNumber = 18)
{
PostClick(204,396)
}
if(MapNumber = 19)
{
PostClick(206,436)
}
if(MapNumber = 20)
{
PostClick(244,450)
}
if(MapNumber = 21)
{
PostClick(274,450)
}
if(MapNumber = 22)
{
PostClick(234,422)
}
if(MapNumber = 23)
{
PostClick(204,396)
}
if(MapNumber = 24)
{
PostClick(204,354)
}
if(MapNumber = 25)
{
PostClick(204,314)
}
if(MapNumber = 26)
{
PostClick(204,274)
}
if(MapNumber = 27)
{
PostClick(204,234)
}
if(MapNumber = 28)
{
PostClick(192,184)
}
if(MapNumber = 29)
{
PostClick(192,144)
}
if(MapNumber = 30)
{
PostClick(232,142)
}
if(MapNumber = 31)
{
PostClick(234,178)
}
if(MapNumber = 32)
{
PostClick(280,206)
}
if(MapNumber = 33)
{
PostClick(316,208)
}
if(MapNumber = 34)
{
PostClick(316,238)
}
if(MapNumber = 35)
{
PostClick(276,238)
}
if(MapNumber = 36)
{
PostClick(276,268)
}
if(MapNumber = 37)
{
PostClick(316,268)
}
if(MapNumber = 38)
{
PostClick(316,298)
}
if(MapNumber = 39)
{
PostClick(276,298)
}
if(MapNumber = 40)
{
PostClick(276,328)
}
if(MapNumber = 41)
{
PostClick(316,328)
}
if(MapNumber = 42)
{
PostClick(316,358)
}
if(MapNumber = 43)
{
PostClick(276,358)
}
if(MapNumber = 44)
{
PostClick(276,388)
}
if(MapNumber = 45)
{
PostClick(316,388)
}
if(MapNumber = 46)
{
PostClick(328,414)
}
if(MapNumber = 47)
{
PostClick(356,438)
}
if(MapNumber = 48)
{
PostClick(356,402)
}
if(MapNumber = 49)
{
PostClick(356,372)
}
if(MapNumber = 50)
{
PostClick(356,342)
}
if(MapNumber = 51)
{
PostClick(356,312)
}
if(MapNumber = 52)
{
PostClick(356,282)
}
if(MapNumber = 53)
{
PostClick(356,252)
}
if(MapNumber = 54)
{
PostClick(356,222)
}
if(MapNumber = 55)
{
PostClick(396,222)
}
if(MapNumber = 56)
{
PostClick(396,252)
}
if(MapNumber = 57)
{
PostClick(396,282)
}
if(MapNumber = 58)
{
PostClick(396,318)
}
if(MapNumber = 59)
{
PostClick(398,350)
}
if(MapNumber = 60)
{
PostClick(394,382)
}
if(MapNumber = 61)
{
PostClick(434,382)
}
if(MapNumber = 62)
{
PostClick(434,350)
}
if(MapNumber = 63)
{
PostClick(434,320)
}
if(MapNumber = 64)
{
PostClick(434,288)
}
if(MapNumber = 65)
{
PostClick(434,258)
}
if(MapNumber = 66)
{
PostClick(434,228)
}
if(MapNumber = 67)
{
PostClick(474,228)
}
if(MapNumber = 68)
{
PostClick(474,258)
}
if(MapNumber = 69)
{
PostClick(474,288)
}
if(MapNumber = 70)
{
PostClick(474,322)
}
if(MapNumber = 71)
{
PostClick(474,352)
}
if(MapNumber = 72)
{
PostClick(474,382)
}
if(MapNumber = 73)
{
PostClick(474,414)
}
if(MapNumber = 74)
{
PostClick(512,447)
}
if(MapNumber = 75)
{
PostClick(512,416)
}
if(MapNumber = 76)
{
PostClick(512,386)
}
if(MapNumber = 77)
{
PostClick(512,356)
}
if(MapNumber = 78)
{
PostClick(512,326)
}
if(MapNumber = 79)
{
PostClick(512,290)
}
if(MapNumber = 80)
{
PostClick(512,260)
}
if(MapNumber = 81)
{
PostClick(512,230)
}
if(MapNumber = 82)
{
PostClick(512,200)
}
if(MapNumber = 83)
{
PostClick(540,200)
}
if(MapNumber = 84)
{
PostClick(550,222)
}
if(MapNumber = 85)
{
PostClick(550,260)
}
if(MapNumber = 86)
{
PostClick(550,296)
}
if(MapNumber = 87)
{
PostClick(550,326)
}
if(MapNumber = 88)
{
PostClick(550,356)
}
if(MapNumber = 89)
{
PostClick(550,386)
}
if(MapNumber = 90)
{
PostClick(550,416)
}
if(MapNumber = 91)
{
PostClick(550,446)
}
if(MapNumber = 92)
{
PostClick(590,446)
}
if(MapNumber = 93)
{
PostClick(590,414)
}
if(MapNumber = 94)
{
PostClick(590,384)
}
if(MapNumber = 95)
{
PostClick(590,352)
}
if(MapNumber = 96)
{
PostClick(590,322)
}
if(MapNumber = 97)
{
PostClick(590,292)
}
if(MapNumber = 98)
{
PostClick(590,262)
}
if(MapNumber = 99)
{
PostClick(590,232)
}
if(MapNumber = 100)
{
PostClick(588,198)
}
if(MapNumber = 101)
{
PostClick(562,178)
}
if(MapNumber = 102)
{
PostClick(586,168)
}
if(MapNumber = 103)
{
PostClick(564,140)
}
if(MapNumber = 104)
{
PostClick(536,168)
}
if(MapNumber = 105)
{
PostClick(502,170)
}
if(MapNumber = 106)
{
PostClick(502,140)
}
if(MapNumber = 107)
{
PostClick(462,140)
}
if(MapNumber = 108)
{
PostClick(462,170)
}
if(MapNumber = 109)
{
PostClick(482,200)
}
if(MapNumber = 110)
{
PostClick(442,200)
}
if(MapNumber = 111)
{
PostClick(402,200)
}
if(MapNumber = 112)
{
PostClick(402,170)
}
if(MapNumber = 113)
{
PostClick(402,140)
}
if(MapNumber = 114)
{
PostClick(402,170)
}
if(MapNumber = 115)
{
PostClick(402,200)
}
if(MapNumber = 116)
{
PostClick(358,186)
}
if(MapNumber = 117)
{
PostClick(342,148)
}
if(MapNumber = 118)
{
PostClick(314,150)
}
if(MapNumber = 119)
{
PostClick(316,178)
}
if(MapNumber = 120)
{
PostClick(280,176)
}
if(MapNumber = 121)
{
PostClick(280,206)
}
if(MapNumber = 122)
{
PostClick(316,208)
}
if(MapNumber = 123)
{
PostClick(316,238)
}
if(MapNumber = 124)
{
PostClick(276,238)
}
if(MapNumber = 125)
{
PostClick(276,268)
}
if(MapNumber = 126)
{
PostClick(316,268)
}
if(MapNumber = 127)
{
PostClick(316,298)
}
if(MapNumber = 128)
{
PostClick(276,298)
}
if(MapNumber = 129)
{
PostClick(276,328)
}
if(MapNumber = 130)
{
PostClick(316,328)
}
if(MapNumber = 131)
{
PostClick(316,358)
}
if(MapNumber = 132)
{
PostClick(276,358)
}
if(MapNumber = 133)
{
PostClick(276,388)
}
if(MapNumber = 134)
{
PostClick(316,388)
}
if(MapNumber = 135)
{
PostClick(328,414)
}
if(MapNumber = 136)
{
PostClick(356,438)
}
if(MapNumber = 137)
{
PostClick(356,402)
}
if(MapNumber = 138)
{
PostClick(356,372)
}
if(MapNumber = 139)
{
PostClick(356,342)
}
if(MapNumber = 140)
{
PostClick(356,312)
}
if(MapNumber = 141)
{
PostClick(356,282)
}
if(MapNumber = 142)
{
PostClick(356,252)
}
if(MapNumber = 143)
{
PostClick(356,222)
}
if(MapNumber = 144)
{
PostClick(396,222)
}
if(MapNumber = 145)
{
PostClick(396,252)
}
if(MapNumber = 146)
{
PostClick(396,282)
}
if(MapNumber = 147)
{
PostClick(396,318)
}
if(MapNumber = 148)
{
PostClick(398,350)
}
if(MapNumber = 149)
{
PostClick(394,382)
}
if(MapNumber = 150)
{
PostClick(434,382)
}
if(MapNumber = 151)
{
PostClick(434,350)
}
if(MapNumber = 152)
{
PostClick(434,320)
}
if(MapNumber = 153)
{
PostClick(434,288)
}
if(MapNumber = 154)
{
PostClick(434,258)
}
if(MapNumber = 155)
{
PostClick(434,228)
}
if(MapNumber = 156)
{
PostClick(474,228)
}
if(MapNumber = 157)
{
PostClick(474,258)
}
if(MapNumber = 158)
{
PostClick(474,288)
}
if(MapNumber = 159)
{
PostClick(474,322)
}
if(MapNumber = 160)
{
PostClick(474,352)
}
if(MapNumber = 161)
{
PostClick(474,382)
}
if(MapNumber = 162)
{
PostClick(474,414)
}
if(MapNumber = 163)
{
PostClick(512,447)
}
if(MapNumber = 164)
{
PostClick(512,416)
}
if(MapNumber = 165)
{
PostClick(512,386)
}
if(MapNumber = 166)
{
PostClick(512,356)
}
if(MapNumber = 167)
{
PostClick(512,326)
}
if(MapNumber = 168)
{
PostClick(512,290)
}
if(MapNumber = 169)
{
PostClick(512,260)
}
if(MapNumber = 170)
{
PostClick(512,230)
}
if(MapNumber = 171)
{
PostClick(512,200)
}
if(MapNumber = 172)
{
PostClick(540,200)
}
if(MapNumber = 173)
{
PostClick(550,222)
}
if(MapNumber = 174)
{
PostClick(550,260)
}
if(MapNumber = 175)
{
PostClick(550,296)
}
if(MapNumber = 176)
{
PostClick(550,326)
}
if(MapNumber = 177)
{
PostClick(550,356)
}
if(MapNumber = 178)
{
PostClick(550,386)
}
if(MapNumber = 179)
{
PostClick(550,416)
}
if(MapNumber = 180)
{
PostClick(550,446)
}
if(MapNumber = 181)
{
PostClick(590,446)
}
if(MapNumber = 182)
{
PostClick(590,414)
}
if(MapNumber = 183)
{
PostClick(590,384)
}
if(MapNumber = 184)
{
PostClick(590,352)
}
if(MapNumber = 185)
{
PostClick(590,322)
}
if(MapNumber = 186)
{
PostClick(590,292)
}
if(MapNumber = 187)
{
PostClick(590,262)
}
if(MapNumber = 188)
{
PostClick(590,232)
}
if(MapNumber = 189)
{
PostClick(588,198)
}
if(MapNumber = 190)
{
PostClick(562,178)
}
if(MapNumber = 191)
{
PostClick(586,168)
}
if(MapNumber = 192)
{
PostClick(564,140)
}
if(MapNumber = 193)
{
PostClick(536,168)
}
if(MapNumber = 194)
{
PostClick(502,170)
}
if(MapNumber = 195)
{
PostClick(502,140)
}
if(MapNumber = 196)
{
PostClick(462,140)
}
if(MapNumber = 197)
{
PostClick(462,170)
}
if(MapNumber = 198)
{
PostClick(482,200)
}
if(MapNumber = 199)
{
PostClick(442,200)
}
if(MapNumber = 200)
{
PostClick(402,200)
}
if(MapNumber = 201)
{
PostClick(402,170)
}
if(MapNumber = 202)
{
PostClick(402,140)
}
if(MapNumber = 203)
{
PostClick(358,186)
}
if(MapNumber = 204)
{
PostClick(342,148)
}
if(MapNumber = 205)
{
PostClick(314,150)
}
if(MapNumber = 206)
{
PostClick(316,178)
}
if(MapNumber = 207)
{
PostClick(280,176)
MapNumber = 120
}
}
}
if(Loute3 = 1)
{
Gosub, 감흥
{
if(MapNumber = 1)
{
PostClick(402,140)
}
if(MapNumber = 2)
{
PostClick(402,170)
}
if(MapNumber = 3)
{
PostClick(402,200)
}
if(MapNumber = 4)
{
PostClick(442,200)
}
if(MapNumber = 5)
{
PostClick(482,200)
}
if(MapNumber = 6)
{
PostClick(462,170)
}
if(MapNumber = 7)
{
PostClick(462,140)
}
if(MapNumber = 8)
{
PostClick(502,140)
}
if(MapNumber = 9)
{
PostClick(502,170)
}
if(MapNumber = 10)
{
PostClick(536,168)
}
if(MapNumber = 11)
{
PostClick(564,140)
}
if(MapNumber = 12)
{
PostClick(586,168)
}
if(MapNumber = 13)
{
PostClick(562,178)
}
if(MapNumber = 14)
{
PostClick(588,198)
}
if(MapNumber = 15)
{
PostClick(540,200)
}
if(MapNumber = 16)
{
PostClick(512,200)
}
if(MapNumber = 17)
{
PostClick(513,230)
}
if(MapNumber = 18)
{
PostClick(550,222)
}
if(MapNumber = 19)
{
PostClick(590,232)
}
if(MapNumber = 20)
{
PostClick(590,262)
}
if(MapNumber = 21)
{
PostClick(550,260)
}
if(MapNumber = 22)
{
PostClick(512,260)
}
if(MapNumber = 23)
{
PostClick(512,290)
}
if(MapNumber = 24)
{
PostClick(550,296)
}
if(MapNumber = 25)
{
PostClick(590,292)
}
if(MapNumber = 26)
{
PostClick(590,322)
}
if(MapNumber = 27)
{
PostClick(550,326)
}
if(MapNumber = 28)
{
PostClick(512,326)
}
if(MapNumber = 29)
{
PostClick(512,356)
}
if(MapNumber = 30)
{
PostClick(550,356)
}
if(MapNumber = 31)
{
PostClick(590,352)
}
if(MapNumber = 32)
{
PostClick(590,384)
}
if(MapNumber = 33)
{
PostClick(550,386)
}
if(MapNumber = 34)
{
PostClick(512,386)
}
if(MapNumber = 35)
{
PostClick(512,416)
}
if(MapNumber = 36)
{
PostClick(550,416)
}
if(MapNumber = 37)
{
PostClick(590,414)
}
if(MapNumber = 38)
{
PostClick(590,446)
}
if(MapNumber = 39)
{
PostClick(550,446)
}
if(MapNumber = 40)
{
PostClick(512,447)
}
if(MapNumber = 41)
{
PostClick(474,414)
}
if(MapNumber = 42)
{
PostClick(474,382)
}
if(MapNumber = 43)
{
PostClick(434,382)
}
if(MapNumber = 44)
{
PostClick(394,382)
}
if(MapNumber = 45)
{
PostClick(356,372)
}
if(MapNumber = 46)
{
PostClick(356,402)
}
if(MapNumber = 47)
{
PostClick(356,438)
}
if(MapNumber = 48)
{
PostClick(328,414)
}
if(MapNumber = 49)
{
PostClick(316,388)
}
if(MapNumber = 50)
{
PostClick(276,388)
}
if(MapNumber = 51)
{
PostClick(276,358)
}
if(MapNumber = 52)
{
PostClick(316,358)
}
if(MapNumber = 53)
{
PostClick(356,342)
}
if(MapNumber = 54)
{
PostClick(398,350)
}
if(MapNumber = 55)
{
PostClick(434,350)
}
if(MapNumber = 56)
{
PostClick(474,352)
}
if(MapNumber = 57)
{
PostClick(474,322)
}
if(MapNumber = 58)
{
PostClick(434,320)
}
if(MapNumber = 59)
{
PostClick(396,318)
}
if(MapNumber = 60)
{
PostClick(356,312)
}
if(MapNumber = 61)
{
PostClick(316,328)
}
if(MapNumber = 62)
{
PostClick(276,328)
}
if(MapNumber = 63)
{
PostClick(276,298)
}
if(MapNumber = 64)
{
PostClick(316,298)
}
if(MapNumber = 65)
{
PostClick(356,282)
}
if(MapNumber = 66)
{
PostClick(396,282)
}
if(MapNumber = 67)
{
PostClick(434,288)
}
if(MapNumber = 68)
{
PostClick(474,288)
}
if(MapNumber = 69)
{
PostClick(474,258)
}
if(MapNumber = 70)
{
PostClick(434,258)
}
if(MapNumber = 71)
{
PostClick(396,252)
}
if(MapNumber = 72)
{
PostClick(356,252)
}
if(MapNumber = 73)
{
PostClick(316,268)
}
if(MapNumber = 74)
{
PostClick(276,268)
}
if(MapNumber = 75)
{
PostClick(276,238)
}
if(MapNumber = 76)
{
PostClick(316,238)
}
if(MapNumber = 77)
{
PostClick(356,222)
}
if(MapNumber = 78)
{
PostClick(396,222)
}
if(MapNumber = 79)
{
PostClick(434,228)
}
if(MapNumber = 80)
{
PostClick(474,228)
}
if(MapNumber = 81)
{
PostClick(482,200)
}
if(MapNumber = 82)
{
PostClick(442,200)
}
if(MapNumber = 83)
{
PostClick(402,200)
}
if(MapNumber = 84)
{
PostClick(358,186)
}
if(MapNumber = 85)
{
PostClick(342,148)
}
if(MapNumber = 86)
{
PostClick(314,150)
}
if(MapNumber = 87)
{
PostClick(316,178)
}
if(MapNumber = 88)
{
PostClick(316,208)
}
if(MapNumber = 89)
{
PostClick(280,206)
}
if(MapNumber = 90)
{
PostClick(234,178)
}
if(MapNumber = 91)
{
PostClick(232,142)
}
if(MapNumber = 92)
{
PostClick(192,144)
}
if(MapNumber = 93)
{
PostClick(192,184)
}
if(MapNumber = 94)
{
PostClick(204,234)
}
if(MapNumber = 95)
{
PostClick(204,274)
}
if(MapNumber = 96)
{
PostClick(204,314)
}
if(MapNumber = 97)
{
PostClick(204,354)
}
if(MapNumber = 98)
{
PostClick(204,396)
}
if(MapNumber = 99)
{
PostClick(206,436)
}
if(MapNumber = 100)
{
PostClick(244,450)
}
if(MapNumber = 101)
{
PostClick(274,450)
}
if(MapNumber = 102)
{
PostClick(234,422)
}
if(MapNumber = 103)
{
PostClick(204,396)
}
if(MapNumber = 104)
{
PostClick(204,354)
}
if(MapNumber = 105)
{
PostClick(204,314)
}
if(MapNumber = 106)
{
PostClick(204,274)
}
if(MapNumber = 107)
{
PostClick(204,234)
}
if(MapNumber = 108)
{
PostClick(192,184)
}
if(MapNumber = 109)
{
PostClick(192,144)
}
if(MapNumber = 110)
{
PostClick(232,142)
}
if(MapNumber = 111)
{
PostClick(234,178)
}
if(MapNumber = 112)
{
PostClick(280,206)
}
if(MapNumber = 113)
{
PostClick(280,176)
}
if(MapNumber = 114)
{
PostClick(316,178)
}
if(MapNumber = 115)
{
PostClick(314,150)
}
if(MapNumber = 116)
{
PostClick(342,148)
}
if(MapNumber = 117)
{
PostClick(358,186)
}
if(MapNumber = 118)
{
PostClick(402,200)
}
if(MapNumber = 119)
{
PostClick(402,170)
}
if(MapNumber = 120)
{
PostClick(402,140)
}
if(MapNumber = 121)
{
PostClick(402,170)
}
if(MapNumber = 122)
{
PostClick(402,200)
}
if(MapNumber = 123)
{
PostClick(442,200)
}
if(MapNumber = 124)
{
PostClick(482,200)
}
if(MapNumber = 125)
{
PostClick(462,170)
}
if(MapNumber = 126)
{
PostClick(462,140)
}
if(MapNumber = 127)
{
PostClick(502,140)
}
if(MapNumber = 128)
{
PostClick(502,170)
}
if(MapNumber = 129)
{
PostClick(536,168)
}
if(MapNumber = 130)
{
PostClick(564,140)
}
if(MapNumber = 131)
{
PostClick(586,168)
}
if(MapNumber = 132)
{
PostClick(562,178)
}
if(MapNumber = 133)
{
PostClick(588,198)
}
if(MapNumber = 134)
{
PostClick(540,200)
}
if(MapNumber = 135)
{
PostClick(512,200)
}
if(MapNumber = 136)
{
PostClick(513,230)
}
if(MapNumber = 137)
{
PostClick(550,222)
}
if(MapNumber = 138)
{
PostClick(590,232)
}
if(MapNumber = 139)
{
PostClick(590,262)
}
if(MapNumber = 140)
{
PostClick(550,260)
}
if(MapNumber = 141)
{
PostClick(512,260)
}
if(MapNumber = 142)
{
PostClick(512,290)
}
if(MapNumber = 143)
{
PostClick(550,296)
}
if(MapNumber = 144)
{
PostClick(590,292)
}
if(MapNumber = 145)
{
PostClick(590,322)
}
if(MapNumber = 146)
{
PostClick(550,326)
}
if(MapNumber = 147)
{
PostClick(512,326)
}
if(MapNumber = 148)
{
PostClick(512,356)
}
if(MapNumber = 149)
{
PostClick(550,356)
}
if(MapNumber = 150)
{
PostClick(590,352)
}
if(MapNumber = 151)
{
PostClick(590,384)
}
if(MapNumber = 152)
{
PostClick(550,386)
}
if(MapNumber = 153)
{
PostClick(512,386)
}
if(MapNumber = 154)
{
PostClick(512,416)
}
if(MapNumber = 155)
{
PostClick(550,416)
}
if(MapNumber = 156)
{
PostClick(590,414)
}
if(MapNumber = 157)
{
PostClick(590,446)
}
if(MapNumber = 158)
{
PostClick(550,446)
}
if(MapNumber = 159)
{
PostClick(512,447)
}
if(MapNumber = 160)
{
PostClick(474,414)
}
if(MapNumber = 161)
{
PostClick(474,382)
}
if(MapNumber = 162)
{
PostClick(434,382)
}
if(MapNumber = 163)
{
PostClick(394,382)
}
if(MapNumber = 164)
{
PostClick(356,372)
}
if(MapNumber = 165)
{
PostClick(356,402)
}
if(MapNumber = 166)
{
PostClick(356,438)
}
if(MapNumber = 167)
{
PostClick(328,414)
}
if(MapNumber = 168)
{
PostClick(316,388)
}
if(MapNumber = 169)
{
PostClick(276,388)
}
if(MapNumber = 170)
{
PostClick(276,358)
}
if(MapNumber = 171)
{
PostClick(316,358)
}
if(MapNumber = 172)
{
PostClick(356,342)
}
if(MapNumber = 173)
{
PostClick(398,350)
}
if(MapNumber = 174)
{
PostClick(434,350)
}
if(MapNumber = 175)
{
PostClick(474,352)
}
if(MapNumber = 176)
{
PostClick(474,322)
}
if(MapNumber = 177)
{
PostClick(434,320)
}
if(MapNumber = 178)
{
PostClick(396,318)
}
if(MapNumber = 179)
{
PostClick(356,312)
}
if(MapNumber = 180)
{
PostClick(316,328)
}
if(MapNumber = 181)
{
PostClick(276,328)
}
if(MapNumber = 182)
{
PostClick(276,298)
}
if(MapNumber = 183)
{
PostClick(316,298)
}
if(MapNumber = 184)
{
PostClick(356,282)
}
if(MapNumber = 185)
{
PostClick(396,282)
}
if(MapNumber = 186)
{
PostClick(434,288)
}
if(MapNumber = 187)
{
PostClick(474,288)
}
if(MapNumber = 188)
{
PostClick(474,258)
}
if(MapNumber = 189)
{
PostClick(434,258)
}
if(MapNumber = 190)
{
PostClick(396,252)
}
if(MapNumber = 191)
{
PostClick(356,252)
}
if(MapNumber = 192)
{
PostClick(316,268)
}
if(MapNumber = 193)
{
PostClick(276,268)
}
if(MapNumber = 194)
{
PostClick(276,238)
}
if(MapNumber = 195)
{
PostClick(316,238)
}
if(MapNumber = 196)
{
PostClick(356,222)
}
if(MapNumber = 197)
{
PostClick(396,222)
}
if(MapNumber = 198)
{
PostClick(434,228)
}
if(MapNumber = 199)
{
PostClick(474,228)
}
if(MapNumber = 200)
{
PostClick(482,200)
}
if(MapNumber = 201)
{
PostClick(442,200)
}
if(MapNumber = 202)
{
PostClick(402,200)
}
if(MapNumber = 203)
{
PostClick(358,186)
}
if(MapNumber = 204)
{
PostClick(342,148)
}
if(MapNumber = 205)
{
PostClick(314,150)
}
if(MapNumber = 206)
{
PostClick(316,178)
}
if(MapNumber = 207)
{
PostClick(316,208)
Mapnumber = 111
}
}
}
if(Loute4 = 1)
{
Gosub, 감흥
{
if(MapNumber = 1)
{
PostClick(402,140)
}
if(MapNumber = 2)
{
PostClick(402,170)
}
if(MapNumber = 3)
{
PostClick(402,200)
}
if(MapNumber = 4)
{
PostClick(358,186)
}
if(MapNumber = 5)
{
PostClick(342,148)
}
if(MapNumber = 6)
{
PostClick(314,150)
}
if(MapNumber = 7)
{
PostClick(316,178)
}
if(MapNumber = 8)
{
PostClick(280,176)
}
if(MapNumber = 9)
{
PostClick(280,206)
}
if(MapNumber = 10)
{
PostClick(234,178)
}
if(MapNumber = 11)
{
PostClick(232,142)
}
if(MapNumber = 12)
{
PostClick(192,144)
}
if(MapNumber = 13)
{
PostClick(192,184)
}
if(MapNumber = 14)
{
PostClick(204,234)
}
if(MapNumber = 15)
{
PostClick(204,274)
}
if(MapNumber = 16)
{
PostClick(204,314)
}
if(MapNumber = 17)
{
PostClick(204,354)
}
if(MapNumber = 18)
{
PostClick(204,396)
}
if(MapNumber = 19)
{
PostClick(206,436)
}
if(MapNumber = 20)
{
PostClick(244,450)
}
if(MapNumber = 21)
{
PostClick(274,450)
}
if(MapNumber = 22)
{
PostClick(234,422)
}
if(MapNumber = 23)
{
PostClick(204,396)
}
if(MapNumber = 24)
{
PostClick(204,354)
}
if(MapNumber = 25)
{
PostClick(204,314)
}
if(MapNumber = 26)
{
PostClick(204,274)
}
if(MapNumber = 27)
{
PostClick(204,234)
}
if(MapNumber = 28)
{
PostClick(192,184)
}
if(MapNumber = 29)
{
PostClick(192,144)
}
if(MapNumber = 30)
{
PostClick(232,142)
}
if(MapNumber = 31)
{
PostClick(234,178)
}
if(MapNumber = 32)
{
PostClick(280,206)
}
if(MapNumber = 33)
{
PostClick(316,208)
}
if(MapNumber = 34)
{
PostClick(316,178)
}
if(MapNumber = 35)
{
PostClick(358,186)
}
if(MapNumber = 36)
{
PostClick(402,200)
}
if(MapNumber = 37)
{
PostClick(442,200)
}
if(MapNumber = 38)
{
PostClick(482,200)
}
if(MapNumber = 39)
{
PostClick(474,228)
}
if(MapNumber = 40)
{
PostClick(434,228)
}
if(MapNumber = 41)
{
PostClick(396,222)
}
if(MapNumber = 42)
{
PostClick(356,222)
}
if(MapNumber = 43)
{
PostClick(316,238)
}
if(MapNumber = 44)
{
PostClick(276,238)
}
if(MapNumber = 46)
{
PostClick(276,268)
}
if(MapNumber = 47)
{
PostClick(316,268)
}
if(MapNumber = 48)
{
PostClick(356,252)
}
if(MapNumber = 49)
{
PostClick(396,252)
}
if(MapNumber = 50)
{
PostClick(434,258)
}
if(MapNumber = 51)
{
PostClick(474,258)
}
if(MapNumber = 52)
{
PostClick(474,288)
}
if(MapNumber = 53)
{
PostClick(434,288)
}
if(MapNumber = 54)
{
PostClick(396,282)
}
if(MapNumber = 55)
{
PostClick(356,282)
}
if(MapNumber = 56)
{
PostClick(316,298)
}
if(MapNumber = 57)
{
PostClick(276,298)
}
if(MapNumber = 58)
{
PostClick(276,328)
}
if(MapNumber = 59)
{
PostClick(316,328)
}
if(MapNumber = 60)
{
PostClick(356,312)
}
if(MapNumber = 61)
{
PostClick(396,318)
}
if(MapNumber = 62)
{
PostClick(434,320)
}
if(MapNumber = 63)
{
PostClick(474,322)
}
if(MapNumber = 64)
{
PostClick(474,352)
}
if(MapNumber = 65)
{
PostClick(434,350)
}
if(MapNumber = 66)
{
PostClick(398,350)
}
if(MapNumber = 67)
{
PostClick(356,342)
}
if(MapNumber = 68)
{
PostClick(316,358)
}
if(MapNumber = 69)
{
PostClick(276,358)
}
if(MapNumber = 70)
{
PostClick(276,388)
}
if(MapNumber = 71)
{
PostClick(316,388)
}
if(MapNumber = 72)
{
PostClick(328,414)
}
if(MapNumber = 73)
{
PostClick(356,438)
}
if(MapNumber = 74)
{
PostClick(356,402)
}
if(MapNumber = 75)
{
PostClick(356,372)
}
if(MapNumber = 76)
{
PostClick(394,382)
}
if(MapNumber = 77)
{
PostClick(434,382)
}
if(MapNumber = 78)
{
PostClick(474,382)
}
if(MapNumber = 79)
{
PostClick(474,414)
}
if(MapNumber = 80)
{
PostClick(512,447)
}
if(MapNumber = 81)
{
PostClick(550,446)
}
if(MapNumber = 82)
{
PostClick(590,446)
}
if(MapNumber = 83)
{
PostClick(590,414)
}
if(MapNumber = 84)
{
PostClick(550,416)
}
if(MapNumber = 85)
{
PostClick(512,416)
}
if(MapNumber = 86)
{
PostClick(512,386)
}
if(MapNumber = 87)
{
PostClick(550,386)
}
if(MapNumber = 88)
{
PostClick(590,384)
}
if(MapNumber = 89)
{
PostClick(590,352)
}
if(MapNumber = 90)
{
PostClick(550,356)
}
if(MapNumber = 91)
{
PostClick(512,356)
}
if(MapNumber = 92)
{
PostClick(512,326)
}
if(MapNumber = 93)
{
PostClick(550,326)
}
if(MapNumber = 94)
{
PostClick(590,322)
}
if(MapNumber = 95)
{
PostClick(590,292)
}
if(MapNumber = 96)
{
PostClick(550,296)
}
if(MapNumber = 97)
{
PostClick(512,290)
}
if(MapNumber = 98)
{
PostClick(512,260)
}
if(MapNumber = 99)
{
PostClick(550,260)
}
if(MapNumber = 100)
{
PostClick(590,262)
}
if(MapNumber = 101)
{
PostClick(590,232)
}
if(MapNumber = 102)
{
PostClick(550,222)
}
if(MapNumber = 103)
{
PostClick(512,230)
}
if(MapNumber = 104)
{
PostClick(512,200)
}
if(MapNumber = 105)
{
PostClick(540,200)
}
if(MapNumber = 106)
{
PostClick(588,198)
}
if(MapNumber = 107)
{
PostClick(562,178)
}
if(MapNumber = 108)
{
PostClick(586,168)
}
if(MapNumber = 109)
{
PostClick(564,140)
}
if(MapNumber = 110)
{
PostClick(536,168)
}
if(MapNumber = 111)
{
PostClick(502,170)
}
if(MapNumber = 112)
{
PostClick(502,140)
}
if(MapNumber = 113)
{
PostClick(462,140)
}
if(MapNumber = 114)
{
PostClick(462,170)
}
if(MapNumber = 115)
{
PostClick(482,200)
}
if(MapNumber = 116)
{
PostClick(442,200)
}
if(MapNumber = 117)
{
PostClick(402,200)
}
if(MapNumber = 118)
{
PostClick(402,170)
}
if(MapNumber = 119)
{
PostClick(402,140)
}
if(MapNumber = 120)
{
PostClick(402,170)
}
if(MapNumber = 121)
{
PostClick(402,200)
}
if(MapNumber = 122)
{
PostClick(358,186)
}
if(MapNumber = 123)
{
PostClick(342,148)
}
if(MapNumber = 124)
{
PostClick(314,150)
}
if(MapNumber = 125)
{
PostClick(316,178)
}
if(MapNumber = 126)
{
PostClick(280,176)
MapNumber = 31
}
}
}
MapNumber += 1
}
CharMovePobuk()
{
if(MapNumber = 1)
{
PostClick(533,355)
RunDirect = 0
}
if(MapNumber = 2)
{
PostClick(573,355)
}
if(MapNumber = 3)
{
PostClick(613,355)
}
if(MapNumber = 4)
{
PostClick(613,385)
}
if(MapNumber = 5)
{
PostClick(575,385)
}
if(MapNumber = 6)
{
PostClick(587,427)
}
if(MapNumber = 7)
{
PostClick(535,435)
}
if(MapNumber = 8)
{
PostClick(531,407)
}
if(MapNumber = 9)
{
PostClick(497,407)
}
if(MapNumber = 10)
{
PostClick(495,375)
}
if(MapNumber = 11)
{
PostClick(495,351)
}
if(MapNumber = 12)
{
PostClick(459,349)
}
if(MapNumber = 13)
{
PostClick(457,309)
}
if(MapNumber = 14)
{
PostClick(459,289)
}
if(MapNumber = 15)
{
PostClick(413,289)
}
if(MapNumber = 16)
{
PostClick(411,325)
}
if(MapNumber = 17)
{
PostClick(411,375)
}
if(MapNumber = 18)
{
PostClick(401,397)
}
if(MapNumber = 19)
{
PostClick(427,399)
}
if(MapNumber = 20)
{
PostClick(411,345)
}
if(MapNumber = 21)
{
PostClick(385,315)
}
if(MapNumber = 22)
{
PostClick(381,283)
}
if(MapNumber = 23)
{
PostClick(375,253)
}
if(MapNumber = 24)
{
PostClick(317,255)
}
if(MapNumber = 25)
{
PostClick(315,297)
}
if(MapNumber = 26)
{
PostClick(315,353)
}
if(MapNumber = 27)
{
PostClick(263,361)
}
if(MapNumber = 28)
{
PostClick(241,307)
}
if(MapNumber = 29)
{
PostClick(207,309)
}
if(MapNumber = 30)
{
PostClick(195,357)
}
if(MapNumber = 31)
{
PostClick(205,393)
}
if(MapNumber = 32)
{
PostClick(229,421)
}
if(MapNumber = 33)
{
PostClick(235,449)
}
if(MapNumber = 34)
{
PostClick(199,451)
}
if(MapNumber = 35)
{
PostClick(207,421)
}
if(MapNumber = 36)
{
PostClick(193,375)
}
if(MapNumber = 37)
{
PostClick(193,331)
}
if(MapNumber = 38)
{
PostClick(199,285)
}
if(MapNumber = 39)
{
PostClick(241,285)
}
if(MapNumber = 40)
{
PostClick(241,257)
}
if(MapNumber = 41)
{
PostClick(197,251)
}
if(MapNumber = 42)
{
PostClick(193,221)
}
if(MapNumber = 43)
{
PostClick(195,179)
}
if(MapNumber = 44)
{
PostClick(219,171)
}
if(MapNumber = 45)
{
PostClick(217,149)
}
if(MapNumber = 46)
{
PostClick(197,141)
}
if(MapNumber = 47)
{
PostClick(197,183)
}
if(MapNumber = 48)
{
PostClick(201,225)
}
if(MapNumber = 49)
{
PostClick(243,219)
}
if(MapNumber = 50)
{
PostClick(269,195)
}
if(MapNumber = 51)
{
PostClick(271,167)
}
if(MapNumber = 52)
{
PostClick(271,135)
}
if(MapNumber = 53)
{
PostClick(313,133)
}
if(MapNumber = 54)
{
PostClick(365,143)
}
if(MapNumber = 55)
{
PostClick(369,179)
}
if(MapNumber = 56)
{
PostClick(315,181)
}
if(MapNumber = 57)
{
PostClick(301,199)
}
if(MapNumber = 58)
{
PostClick(341,203)
}
if(MapNumber = 59)
{
PostClick(373,195)
}
if(MapNumber = 60)
{
PostClick(409,175)
}
if(MapNumber = 61)
{
PostClick(441,175)
}
if(MapNumber = 62)
{
PostClick(441,137)
}
if(MapNumber = 63)
{
PostClick(477,131)
}
if(MapNumber = 64)
{
PostClick(523,131)
}
if(MapNumber = 65)
{
PostClick(579,135)
}
if(MapNumber = 66)
{
PostClick(595,157)
}
if(MapNumber = 67)
{
PostClick(599,187)
}
if(MapNumber = 68)
{
PostClick(557,155)
}
if(MapNumber = 69)
{
PostClick(501,133)
}
if(MapNumber = 70)
{
PostClick(441,133)
}
if(MapNumber = 71)
{
PostClick(441,167)
}
if(MapNumber = 72)
{
PostClick(483,173)
}
if(MapNumber = 73)
{
PostClick(519,177)
}
if(MapNumber = 74)
{
PostClick(547,193)
}
if(MapNumber = 75)
{
PostClick(567,225)
}
if(MapNumber = 76)
{
PostClick(599,241)
}
if(MapNumber = 77)
{
PostClick(607,265)
}
if(MapNumber = 78)
{
PostClick(561,259)
}
if(MapNumber = 79)
{
PostClick(511,273)
}
if(MapNumber = 80)
{
PostClick(481,305)
RunDirect = 1
}
if(RunDirect = 0)
{
MapNumber += 1
}
if(RunDirect = 1)
{
MapNumber -= 1
}
}
ReadAbility(WeaponName)
{
SetFormat, integer, h
if(WeaponName = "격투")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0xA9, 0xAC, 0x2C, 0xD2)
}
if(WeaponName = "검")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x80, 0xAC)
}
if(WeaponName = "단검")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0xE8, 0xB2, 0x80, 0xAC)
}
if(WeaponName = "도")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0xC4, 0xB3, 0x00)
}
if(WeaponName = "도끼")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0xC4, 0xB3, 0x7C, 0xB0)
}
if(WeaponName = "거대도끼")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x70, 0xAC, 0x00, 0xB3, 0xC4, 0xB3, 0x7C, 0xB0)
}
if(WeaponName = "대검")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x00, 0xB3, 0x80, 0xAC)
}
if(WeaponName = "대도")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x00, 0xB3, 0xC4, 0xB3)
}
if(WeaponName = "창, 특수창")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x3D, 0xCC, 0x2C, 0x00, 0x20, 0x00, 0xB9, 0xD2, 0x18, 0xC2, 0x3D, 0xCC)
}
if(WeaponName = "봉, 해머")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x09, 0xBD, 0x2C, 0x00, 0x20, 0x00, 0x74, 0xD5, 0x38, 0xBA)
}
if(WeaponName = "현금")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x04, 0xD6, 0x08, 0xAE)
}
if(WeaponName = "활")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x5C, 0xD6)
}
if(WeaponName = "거대검")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x70, 0xAC, 0x00, 0xB3, 0x80, 0xAC)
}
if(WeaponName = "거대도")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x70, 0xAC, 0x00, 0xB3, 0xC4, 0xB3)
}
if(WeaponName = "양손단검")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x91, 0xC5, 0x90, 0xC1, 0xE8, 0xB2, 0x80, 0xAC)
}
if(WeaponName = "양손도끼")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0x91, 0xC5, 0x90, 0xC1, 0xC4, 0xB3, 0x7C, 0xB0)
}
if(WeaponName = "스태프")
{
ReadAbilityADD := jelan.processPatternScan( 0x00000000, 0x7FFFFFFF, 0x18, 0x20, 0x53, 0x00, 0xA4, 0xC2, 0xDC, 0xD0, 0x04, 0xD5)
}
ReadAbilityADD := ReadAbilityADD + 0x208
SetFormat, integer, d
ReadAbility := jelan.read(ReadAbilityADD, "UInt", aOffsets*)
Return, ReadAbility
}
ReadAbilityNameValue()
{
AbilityName := jelan.readString(AbilityNameADD, 20, "UTF-16", aOffsets*)
AbilityValue := jelan.read(AbilityValueADD, "UShort", aOffsets*)
}
SendWeaponName(WeaponName)
{
if(WeaponName = "격투")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, rurxn{Enter}
}
if(WeaponName = "검")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, rja{Enter}
}
if(WeaponName = "단검")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eksrja{Enter}
}
if(WeaponName = "도")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eh{Enter}
}
if(WeaponName = "도끼")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ehRl{Enter}
}
if(WeaponName = "거대도끼")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, rjeoehRl{Enter}
}
if(WeaponName = "대검")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eorja{Enter}
}
if(WeaponName = "대도")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eoeh{Enter}
}
if(WeaponName = "창, 특수창")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ckd,{Space}xmrtnckd{Enter}
}
if(WeaponName = "봉, 해머")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qhd,{Space}goaj{Enter}
}
if(WeaponName = "현금")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, gusrma{Enter}
}
if(WeaponName = "활")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ghkf{Enter}
}
if(WeaponName = "거대검")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, rjeorja{Enter}
}
if(WeaponName = "거대도")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, rjeoeh{Enter}
}
if(WeaponName = "양손단검")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, didthseksrja{Enter}
}
if(WeaponName = "양손도끼")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, didthsehRl{Enter}
}
if(WeaponName = "스태프")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, tmxovm{Enter}
}
if(WeaponName = "대화")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eoghk{Enter}
}
if(WeaponName = "명상")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, audtkd{Enter}
}
if(WeaponName = "집중")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, wlqwnd{Enter}
}
if(WeaponName = "회피")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ghlvl{Enter}
}
if(WeaponName = "몸통지르기")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ahaxhdwlfmrl{Enter}
}
if(WeaponName = "민첩향상")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, alscjqgidtkd{Enter}
}
if(WeaponName = "체력향상")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, cpfurgidtkd{Enter}
}
if(WeaponName = "활방어")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ghkfqkddj{Enter}
}
if(WeaponName = "RemoveArmor")
{
ime_status := % IME_CHECK("A")
if (ime_status = "1")
{
Send, {vk15sc138}
Sleep, 100
}
Send, RemoveArmor{Enter}
}
if(WeaponName = "엘")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, dpf{Enter}
}
if(WeaponName = "테스")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, xptm{Enter}
}
if(WeaponName = "마하")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, akgk{Enter}
}
if(WeaponName = "브리깃드")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qmflrltem{Enter}
}
if(WeaponName = "다뉴")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, eksb{Enter}
}
if(WeaponName = "브라키")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qmfkzl{Enter}
}
}
SendMagicName(MagicName)
{
if(MagicName = "쿠로")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, znfh{Enter}
}
if(MagicName = "나프")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, skvm{Enter}
}
if(MagicName = "베네피쿠스")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qpspvlzntm{Enter}
}
if(MagicName = "브리스")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qmfltm{Enter}
}
if(MagicName = "파라스")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, vkfktm{Enter}
}
if(MagicName = "파스티")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, vktmxl{Enter}
}
if(MagicName = "다라")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, ekfk{Enter}
}
if(MagicName = "마스")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, aktm{Enter}
}
if(MagicName = "라크")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, fkzm{Enter}
}
if(MagicName = "슈키")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, tbzl{Enter}
}
if(MagicName = "클리드")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, zmfflem{Enter}
}
if(MagicName = "저주")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, wjwn{Enter}
}
if(MagicName = "번개")
{
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send, {vk15sc138}
Sleep, 100
}
Send, qjsro{Enter}
}
}
UriEncode(Uri, Enc = "UTF-8")
{
StrPutVar(Uri, Var, Enc)
f := A_FormatInteger
SetFormat, IntegerFast, H
Loop
{
Code := NumGet(Var, A_Index - 1, "UChar")
If (!Code)
Break
If (Code >= 0x30 && Code <= 0x39
|| Code >= 0x41 && Code <= 0x5A
|| Code >= 0x61 && Code <= 0x7A)
Res .= Chr(Code)
Else
Res .= "%" . SubStr(Code + 0x100, -1)
}
SetFormat, IntegerFast, %f%
Return, Res
}
UriDecode(Uri, Enc = "UTF-8")
{
Pos := 1
Loop
{
Pos := RegExMatch(Uri, "i)(?:%[\da-f]{2})+", Code, Pos++)
If (Pos = 0)
Break
VarSetCapacity(Var, StrLen(Code) // 3, 0)
StringTrimLeft, Code, Code, 1
Loop, Parse, Code, `%
NumPut("0x" . A_LoopField, Var, A_Index - 1, "UChar")
StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, Enc), All
}
Return, Uri
}
StrPutVar(Str, ByRef Var, Enc = "")
{
Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
VarSetCapacity(Var, Len, 0)
Return, StrPut(Str, &Var, Enc)
}
return
감응:
Gui, Submit, Nohide
if(Gui_KON = 1)
{
IfInString,Location,[알파차원] 포프레스네 마을
{
Sleep, 1000
}
IfInString,Location,[알파차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, AAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, AAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
IfInString,Location,[베타차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, BAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, BAS, "UInt")
value := jelan.write(0x00527B1C, BAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
IfInString,Location,[감마차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, GAD, "UInt")
value := jelan.write(0x00527B1C, GAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, GAS, "UInt")
value := jelan.write(0x00527B1C, GAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
}
return
감흥:
Gui, Submit, Nohide
if(Gui_KON = 1)
{
IfInString,Location,[알파차원] 포프레스네 마을
{
Sleep, 1000
}
IfInString,Location,[알파차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, AAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, AAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
IfInString,Location,[베타차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, BAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, BAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
IfInString,Location,[감마차원] 포프레스네 남쪽
{
if (countsignal = 0)
{
value := jelan.write(0x00527B1C, GAD, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal += 1
return
}
if (countsignal = 1)
{
value := jelan.write(0x00527B1C, GAS, "UInt")
Sleep, 30
Send, {F14}
Sleep, 100
Send, {F14}
Sleep, 100
countsignal = 0
return
}
}
}
return
end::
pause
return


; if return true, npcID is in file for server
; if return false, npcID is not in file for server
getNpcidFromFile(){

if(npcServer = 알파){
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 알파동파
{
AAD := %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 알파서파
{
AAS := %A_LoopReadLine%
break
}
}

if(AAD = "" || AAS = "" ){
    return false
}
}

if(npcServer = 베타){
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 베타동파
{
BAD := %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine,베타서파
{
BAS := %A_LoopReadLine%
break
}
}

if(BAD = "" || BAS = "" ){
    return false
}
}

if(npcServer = 감마){
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 감마동파
{
GAD := %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 감마서파
{
GAS := %A_LoopReadLine%
break
}
}


if(GAD = "" || GAS = "" ){
    return false
}
}

StringMid, AAD, AAD, 7, 11
StringMid, AAS, AAS, 7, 11
StringMid, BAD, BAD, 7, 11
StringMid, BAS, BAS, 7, 11
StringMid, GAD, GAD, 7, 11
StringMid, GAS, GAS, 7, 11

return true
}

; npcCategory = 알파동파, 알파서파, 베타동파, 베타서파, 감마동파, 감마서파
; npcID = npcID
setNpcidToFile(ser, npcCategory, npcID){
    ;write to file
    FileAppend, %ser%%npcCategory% = %npcID%`n, c:\log.txt
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = "")
{
if(Param1 = Apply)
{
DllCall("LoadLibrary", str, DLL)
DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
}
else if(Param1 = 0)
{
DllCall(DLL . "\USkinExit")
}
}

RemoteM()
{
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x0052794C, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
WriteMemory2(WVALUE,MADDRESS,PROGRAM)
{
Process, wait, %PROGRAM%, 0.5
PID = %ErrorLevel%
if PID = 0
{
Return
}
ProcessHandle := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
DllCall("WriteProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Uint*", WVALUE, "Uint", 07, "Uint *", 0)
DllCall("CloseHandle", "int", ProcessHandle)
Return
}
WPdisablescript()
{
SetFormat, Integer, HEX
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
WPDValue = 01BB000000F8B8
WPDValue2 = 000000BE000000
WPDValue3 = F6C45EE81E6A00
WPDValue4 = FFF4487BE859FF
WPDValue5 = D5E8FF438DF88B
WPDValue6 = 8D194788FFEF72
WPDValue7 = 24448D50242444
WPDValue8 = FFED5D55E8501C
WPDValue9 = 89661824448B66
WPDValue10 = 2424448B661A47
WPDValue11 = E8C78B1C478966
WPDValue12 = C3FFF4544A
Addrs := 0x0058D250
H1 := SubStr(WPDValue, 1, 14)
H2 := Substr(WPDValue2, 1, 14)
H3 := Substr(WPDValue3, 1, 14)
H4 := Substr(WPDValue4, 1, 14)
H5 := Substr(WPDValue5, 1, 14)
H6 := Substr(WPDValue6, 1, 14)
H7 := Substr(WPDValue7, 1, 14)
H8 := Substr(WPDValue8, 1, 14)
H9 := Substr(WPDValue9, 1, 14)
H10 := Substr(WPDValue10, 1, 14)
H11 := Substr(WPDValue11, 1, 14)
H12 := Substr(WPDValue12, 1, 14)
writememory2("0x"H1, Addrs, PID)
writememory2("0x"H2, Addrs+7, PID)
writememory2("0x"H3, Addrs+14, PID)
writememory2("0x"H4, Addrs+21, PID)
writememory2("0x"H5, Addrs+28, PID)
writememory2("0x"H6, Addrs+35, PID)
writememory2("0x"H7, Addrs+42, PID)
writememory2("0x"H8, Addrs+49, PID)
writememory2("0x"H9, Addrs+56, PID)
writememory2("0x"H10, Addrs+63, PID)
writememory2("0x"H11, Addrs+70, PID)
writememory2("0x"H12, Addrs+77, PID)
}
WPD()
{
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x0058D250, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
incineratescript()
{
SetFormat, Integer, HEX
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
inci = 8B0058DAD4A160
inci2 = 808B0000017880
inci3 = 08408B000000BE
inci4 = 64C283D231188D
inci5 = C3834974D2854A
inci6 = 8BF374003B8304
inci7 = 8B04588B038BCB
inci8 = F63108408B0840
inci9 = 0166388B02C083
inci10 = 8DF375FF8566FE
inci11 = E6C1005909C005
inci12 = 66388B02C08310
inci13 = F375FF8566FE01
inci14 = 8B10EEC1F78966
inci15 = EB0474FE3966D9
inci16 = 5B8B1B8BC361B2
inci17 = F6914CE81E6A04
inci18 = FFF415B7E859FF
inci19 = 641A40C7195888
inci20 = F4215EE8000000
inci21 = DBEBFF
Addrs := 0x00590500
I1 := SubStr(inci, 1, 14)
I2 := Substr(inci2, 1, 14)
I3 := Substr(inci3, 1, 14)
I4 := Substr(inci4, 1, 14)
I5 := Substr(inci5, 1, 14)
I6 := Substr(inci6, 1, 14)
I7 := Substr(inci7, 1, 14)
I8 := Substr(inci8, 1, 14)
I9 := Substr(inci9, 1, 14)
I10 := Substr(inci10, 1, 14)
I11 := Substr(inci11, 1, 14)
I12 := Substr(inci12, 1, 14)
I13 := Substr(inci13, 1, 14)
I14 := Substr(inci14, 1, 14)
I15 := Substr(inci15, 1, 14)
I16 := Substr(inci16, 1, 14)
I17 := Substr(inci17, 1, 14)
I18 := Substr(inci18, 1, 14)
I19 := Substr(inci19, 1, 14)
I20 := Substr(inci20, 1, 14)
I21 := Substr(inci21, 1, 14)
writememory2("0x"I1, Addrs, PID)
writememory2("0x"I2, Addrs+7, PID)
writememory2("0x"I3, Addrs+14, PID)
writememory2("0x"I4, Addrs+21, PID)
writememory2("0x"I5, Addrs+28, PID)
writememory2("0x"I6, Addrs+35, PID)
writememory2("0x"I7, Addrs+42, PID)
writememory2("0x"I8, Addrs+49, PID)
writememory2("0x"I9, Addrs+56, PID)
writememory2("0x"I10, Addrs+63, PID)
writememory2("0x"I11, Addrs+70, PID)
writememory2("0x"I12, Addrs+77, PID)
writememory2("0x"I13, Addrs+84, PID)
writememory2("0x"I14, Addrs+91, PID)
writememory2("0x"I15, Addrs+98, PID)
writememory2("0x"I16, Addrs+105, PID)
writememory2("0x"I17, Addrs+112, PID)
writememory2("0x"I18, Addrs+119, PID)
writememory2("0x"I19, Addrs+126, PID)
writememory2("0x"I20, Addrs+133, PID)
writememory2("0x"I21, Addrs+140, PID)
}
incinerate()
{
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x00590500, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
inviteparty()
{
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x0058FE00, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
Poidget(TagetProc)
{
SetTitleMatchMode, 3
CharOID := 0
Get_CharOID := 0
WinGet, pid, PID, %TagetProc%
ProcHwnd := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", PID, "UInt")
DllCall("ReadProcessMemory","UInt",ProcHwnd,"UInt",0x0058DAD4,"Str",CharOID,"UInt",4,"UInt *",0)
Loop 4
result += *(&CharOID + A_Index-1) << 8*(A_Index-1)
result := result+98
DllCall("ReadProcessMemory","UInt",ProcHwnd,"UInt",result,"Str",CharOID,"UInt",4,"UInt *",0)
Loop 4
Get_CharOID += *(&CharOID + A_Index-1) << 8*(A_Index-1)
DllCall("CloseHandle", "int", ProcHwnd)
Return, Get_CharOID
}
Poidwrite()
{
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
ChangeAddr := 0x0058FE20
DllCall("WriteProcessMemory", "UInt", ProcHwnd, "UInt", ChangeAddr, "UInt*", ChangeValue, "UInt", 07, "Uint *", 0)
DllCall("CloseHandle", "int", ProcHwnd)
return
}
RPscript()
{
SetFormat, Integer, HEX
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
ChangeValue = FFF698BDE81F6AC6FFF419D0E859FE200D8B011940CCE81A48890058C3FFF428
Addrs := 0x0058FE00
Loop
{
A := SubStr(ChangeValue, 1, 14)
C := Substr(ChangeValue, 15)
ChangeValue := C
writememory2("0x"A, Addrs, PID)
Addrs := Addrs+7
if(Instr(A,"C3"))
{
break
}
}
}
party()
{
Gui, Submit, Nohide
CharID_1 := 0
CharID_2 := 0
CharID_3 := 0
CharID_4 := 0
CharID_5 := 0
CharID_6 := 0
loop, 1
{
Gui, Submit, Nohide
GuiControlGet, CheckName, , Name1
if (CheckName != "파티원")
{
CharID_1 := Poidget(CheckName)
}
GuiControlGet, CheckName, , Name2
if (CheckName != "파티원")
{
CharID_2 := Poidget(CheckName)
}
GuiControlGet, CheckName, , Name3
if (CheckName != "파티원")
{
CharID_3 := Poidget(CheckName)
}
GuiControlGet, CheckName, , Name4
if (CheckName != "파티원")
{
CharID_4 := Poidget(CheckName)
}
GuiControlGet, CheckName, , Name5
if (CheckName != "파티원")
{
CharID_5 := Poidget(CheckName)
}
GuiControlGet, CheckName, , Name6
if (CheckName != "파티원")
{
CharID_6 := Poidget(CheckName)
}
Gui, Submit, Nohide
GuiControlGet, CheckName, , MainName
RPscript()
ChangeValue := CharID_1
Poidwrite()
inviteparty()
Sleep, 200
ChangeValue := CharID_2
Poidwrite()
inviteparty()
Sleep, 200
ChangeValue := CharID_3
Poidwrite()
inviteparty()
Sleep, 200
ChangeValue := CharID_4
Poidwrite()
inviteparty()
Sleep, 200
ChangeValue := CharID_5
Poidwrite()
inviteparty()
Sleep, 200
ChangeValue := CharID_6
Poidwrite()
inviteparty()
Sleep, 200
}
}
getServer(){
Get_Location()

msgbox, "GetServer" :: %Location%

IfInString,Location,알파
{
npcServer := 알파
}
IfInString,Location,베타
{
npcServer := 베타
}
IfInString,Location,감마
{
npcServer := 감마 
}

        msgbox, GetServer npcServer :: %npcServer%
}
ATKM()
{
SetFormat, Integer, HEX
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
ATKValue = 0D5ED900046683
ATKValue2 = 00003E000F46C7
ATKValue3 = FFED0907E9
Addrs := 0x0058FF00
U1 := SubStr(ATKValue, 1, 14)
U2 := Substr(ATKValue2, 1, 14)
U3 := Substr(ATKValue3, 1, 14)
writememory2("0x"U1, Addrs, PID)
writememory2("0x"U2, Addrs+7, PID)
writememory2("0x"U3, Addrs+14, PID)
}
KeyClick(Key){
if(Key = "AltR"){
loop, 1 {
PostMessage, 0x100, 18, 540540929,, %WindowTitle%
PostMessage, 0x100, 82, 1245185,, %WindowTitle%
PostMessage, 0x101, 82, 1245185,, %WindowTitle%
PostMessage, 0x101, 18, 540540929,, %WindowTitle%
sleep, 1
}
}
else if(Key = "Space"){
loop, 1 {
PostMessage, 0x100, 32, 3735553,, %WindowTitle%
PostMessage, 0x101, 32, 3735553,, %WindowTitle%
}
}
else if(Key = "Tab"){
loop, 1 {
PostMessage, 0x100, 9, 983041,, %WindowTitle%
PostMessage, 0x101, 9, 983041,, %WindowTitle%
}
}
else if(Key = "Alt2"){
loop, 1 {
PostMessage, 0x100, 18, 540540929,, %WindowTitle%
postmessage, 0x100, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 50, 196609, ,%WindowTitle%
PostMessage, 0x101, 18, 540540929,, %WindowTitle%
sleep, 1
}
}
else if(Key=1){
loop, 1 {
postmessage, 0x100, 49, 131073, ,%WindowTitle%
postmessage, 0x101, 49, 131073, ,%WindowTitle%
sleep, 1
}
}
else if(Key=2) {
loop, 1 {
postmessage, 0x100, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 50, 196609, ,%WindowTitle%
sleep, 1
}
}
else if(Key=3) {
loop, 1 {
postmessage, 0x100, 51, 262145, ,%WindowTitle%
postmessage, 0x101, 51, 262145, ,%WindowTitle%
sleep, 1
}
}
else if(Key=4) {
loop, 1 {
postmessage, 0x100, 52, 327681, ,%WindowTitle%
postmessage, 0x101, 52, 327681, ,%WindowTitle%
sleep, 1
}
}
else if(Key=5){
loop, 1{
postmessage, 0x100, 53, 393217, ,%WindowTitle%
postmessage, 0x101, 53, 393217, ,%WindowTitle%
sleep, 1
}
}
else if(Key=6){
loop, 1{
postmessage, 0x100, 54, 458753, ,%WindowTitle%
postmessage, 0x101, 54, 458753, ,%WindowTitle%
sleep, 1
}
}
else if(Key=7){
loop, 1{
postmessage, 0x100, 55, 524289, ,%WindowTitle%
postmessage, 0x101, 55, 524289, ,%WindowTitle%
sleep, 1
}
}
else if(Key=8){
loop, 1{
postmessage, 0x100, 56, 589825, ,%WindowTitle%
postmessage, 0x101, 56, 589825, ,%WindowTitle%
sleep, 1
}
}
else if(Key=9){
loop, 1{
postmessage, 0x100, 57, 655361, ,%WindowTitle%
postmessage, 0x101, 57, 655361, ,%WindowTitle%
sleep, 1
}
}
else if(Key=0){
loop, 1{
postmessage, 0x100, 48, 720897, ,%WindowTitle%
postmessage, 0x101, 48, 720897, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL1"){
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 49, 131073, ,%WindowTitle%
postmessage, 0x101, 49, 131073, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL2"){
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL3") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 51, 262145, ,%WindowTitle%
postmessage, 0x101, 51, 262145, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL4") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 52, 327681, ,%WindowTitle%
postmessage, 0x101, 52, 327681, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL5") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 53, 393217, ,%WindowTitle%
postmessage, 0x101, 53, 393217, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL6") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 54, 458753, ,%WindowTitle%
postmessage, 0x101, 54, 458753, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL7") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 55, 524289, ,%WindowTitle%
postmessage, 0x101, 55, 524289, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL8") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 56, 589825, ,%WindowTitle%
postmessage, 0x101, 56, 589825, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL9") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 57, 655361, ,%WindowTitle%
postmessage, 0x101, 57, 655361, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="CTRL0") {
loop, 1 {
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 48, 720897, ,%WindowTitle%
postmessage, 0x101, 48, 720897, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(Key="DownArrow") {
loop, 1 {
postmessage, 0x100, 40, 22020097, ,%WindowTitle%
postmessage, 0x101, 40, 22020097, ,%WindowTitle%
sleep, 1
}
}
else if(Key="UpArrow") {
loop, 1 {
postmessage, 0x100, 38, 21495809, ,%WindowTitle%
postmessage, 0x101, 38, 21495809, ,%WindowTitle%
sleep, 1
}
}
else if(Key="RightArrow") {
loop, 1 {
postmessage, 0x100, 39, 21823489, ,%WindowTitle%
postmessage, 0x101, 39, 21823489, ,%WindowTitle%
sleep, 1
}
}
else if(Key="LeftArrow") {
loop, 1 {
postmessage, 0x100, 37, 21692417, ,%WindowTitle%
postmessage, 0x101, 37, 21692417, ,%WindowTitle%
sleep, 1
}
}
}

ReadMemory(MADDRESS=0, BYTES=4){
PROGRAM:= WindowTitle
Static OLDPROC, ProcessHandle
VarSetCapacity(buffer, BYTES)
If (PROGRAM != OLDPROC){
if ProcessHandle
closed := DllCall("CloseHandle", "UInt", ProcessHandle), ProcessHandle := 0, OLDPROC := ""
if PROGRAM{
WinGet, pid, pid, % OLDPROC := PROGRAM
if !pid
return "Process Doesn't Exist", OLDPROC := ""
ProcessHandle := DllCall("OpenProcess", "Int", 16, "Int", 0, "UInt", pid)
}
}
If !(ProcessHandle && DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Ptr", &buffer, "UInt", BYTES, "Ptr", 0))
return !ProcessHandle ? "Handle Closed: " closed : "Fail"
else if (BYTES = 1)
Type := "UChar"
else if (BYTES = 2)
Type := "UShort"
else if (BYTES = 4)
Type := "UInt"
else
Type := "Int64"
return numget(buffer, 0, Type)
}
MIC()
{
SetFormat, Integer, HEX
SetTitleMatchMode, 3
WinGet, pid, PID, ahk_pid %jPID%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
MICValue = 2574000004623D
MICValue2 = 0004643D001F0F
MICValue3 = 3D001F0F2E7400
MICValue4 = 0F377400000465
MICValue5 = 500C4EB60F001F
MICValue6 = BF03E93C2474FF
MICValue7 = B80C4EB60FFFEE
MICValue8 = 74FF5000000469
MICValue9 = FFEEBEF0E93C24
MICValue10 = 0469B80C4EB60F
MICValue11 = 3C2474FF500000
MICValue12 = B60FFFEEBEDDE9
MICValue13 = 00000469B80C4E
MICValue14 = CAE93C2474FF50
MICValue15 = FFEEBE
Addrs := 0x0058F400
MC1 := SubStr(MICValue, 1, 14)
MC2 := Substr(MICValue2, 1, 14)
MC3 := Substr(MICValue3, 1, 14)
MC4 := Substr(MICValue4, 1, 14)
MC5 := Substr(MICValue5, 1, 14)
MC6 := Substr(MICValue6, 1, 14)
MC7 := Substr(MICValue7, 1, 14)
MC8 := Substr(MICValue8, 1, 14)
MC9 := Substr(MICValue9, 1, 14)
MC10 := Substr(MICValue10, 1, 14)
MC11 := Substr(MICValue11, 1, 14)
MC12 := Substr(MICValue12, 1, 14)
MC13 := Substr(MICValue13, 1, 14)
MC14 := Substr(MICValue14, 1, 14)
MC15 := Substr(MICValue15, 1, 14)
writememory2("0x"MC1, Addrs, PID)
writememory2("0x"MC2, Addrs+7, PID)
writememory2("0x"MC3, Addrs+14, PID)
writememory2("0x"MC4, Addrs+21, PID)
writememory2("0x"MC5, Addrs+28, PID)
writememory2("0x"MC6, Addrs+35, PID)
writememory2("0x"MC7, Addrs+42, PID)
writememory2("0x"MC8, Addrs+49, PID)
writememory2("0x"MC9, Addrs+56, PID)
writememory2("0x"MC10, Addrs+63, PID)
writememory2("0x"MC11, Addrs+70, PID)
writememory2("0x"MC13, Addrs+77, PID)
writememory2("0x"MC13, Addrs+84, PID)
writememory2("0x"MC14, Addrs+91, PID)
writememory2("0x"MC15, Addrs+98, PID)
}
GetPrivateWorkingSet(PID) {
bytes := ComObjGet("winmgmts:") .ExecQuery("Select * from Win32_PerfFormattedData_PerfProc_Process Where IDProcess=" PID) .ItemIndex(0).WorkingSetPrivate
byte := bytes/1024
Return
}
F11::
Pause
Return
f12::
ExitApp
Return