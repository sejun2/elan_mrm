Global ThisWindowTitle := "H-Elancia Alpha - V1.0.2"
Global AAI, AAD, AAS, BAI, BAD, BAS, GAI, GAD, GAS
if not A_IsAdmin {
MsgBox, 관리자 권한으로 실행해주세요
ExitApp
}
#SingleInstance, off
#NoEnv
#Persistent
#KeyHistory 0
#NoTrayIcon
#Warn All, Off
ListLines, OFF
DetectHiddenText, On
DetectHiddenWindows, On
CoordMode, Mouse, Client
CoordMode, pixel, Client
SetWinDelay, 0
SetControlDelay, 0
SetKeyDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetTitleMatchMode,3
SetBatchLines, -1
Setworkingdir,%a_scriptdir%
Global Coin,WindowTitle,WindowTitle1,WindowTitle2,WindowTitle3,WindowTitle4,WindowTitle5,WindowTitle6,WindowTitle7,WindowTitle8,WindowTitle9,WindowTitle10
Global WinMode, npcidinifile
isFirstTimeRunThisCode := 0
Global jElancia_Count := Get_jElancia_Titles()
GLobal dlm:=";"
Global oldnpcid := 0
Global newnpcid := 0
WindowTitle := WindowTitle1
gosub, Setting_Values
gosub, LoadData
gosub, ShowGui
gosub, run_this
SetStaticColor(hTest1, 0xFF0000)
return
Setting_Values:
Global Category := ["Basic_Setting","Char_Setting","Tab1_Setting","wanteditems","Mines","InTab_Check_Menu", "AutoBuyItem","AutoBuyInk","AutoBuyPant","AutoBuyNeckla"]
Global Category_Count := 0
for key, value in Category
Category_Count++
Global Basic_Setting := ["GuiX", "GuiY", "WinMode"]
Loop, 10
{
Basic_Setting.Insert("Player" . A_Index . "Title")
Basic_Setting.Insert("Player" . A_Index . "Title_Selected")
}
Loop, 7
{
Basic_Setting.Insert("partyPlayer" . A_Index . "Title")
Basic_Setting.Insert("partyPlayer" . A_Index . "Title_Selected")
}
Global Char_Setting := ["critical_hppercent","hpshortcut","critical_mppercent","mpshortcut","critical_fppercent","fpshortcut","Mode"]
Global critical_hppercent, hpshortcut, critical_mppercent, mpshortcut, critical_fppercent, fpshortcut, Mode
Global Tab1_Setting := ["readShortCut", "CheaseShortCut", "SearchDelay", "Book", "BreadShortCut","Bread_Sellers","SearchMoveDelay","Bread_Select","Cheese_Select","meditation","talk","meditation_select","talk_select","Weapon_Change","noweapon","robweapon","robweapon_Select","rob","rob_Select","rob2","rob2_Select","rob3","rob3_Select","rob_target_x","rob_target_y","soya_x","soya_y","soya_n","soya_c"]
Loop, 5
{
Tab1_Setting.Insert("Weapon" . A_Index )
}
Loop, 10
{
Tab1_Setting.Insert("Southern_Exc1_Player" . A_Index . "_check")
Tab1_Setting.Insert("Southern_Exc2_Player" . A_Index . "_check")
Tab1_Setting.Insert("Gamble_Exc1_Player" . A_Index . "_check")
}
Global wanteditems := ["깨끗한물","마늘","리모날개","리모퀸날개","천","비단","실","순록가죽"]
Global Mines := ["무로", "델린", "파시리온","미리온","엘리시온","테스시온","브리쉘","라마트","카잘리온","암피","블렌드","세라지","알타니트","너그","주괴금색","주괴은색","미르","이아","오르","보물상자"]
Global AutoBuyItem := ["식초","후추","간장","마늘","밀가루반죽","버터","쌀","사과","토마토","당근","감자","빈병","우유","스파게티면","다진소고기","올리브기름","프랑크소시지","유부","달걀","딸기","소금","설탕"]
Global AutoBuyInk := ["지렁이병소","지렁이병중","지렁이병대","하늘색","연두색","황토색","보라색","분홍색","자주색","검정색","연자색","주황색","군청색","파랑색","노란색","연갈색","빨간색","하얀색"]
Global AutoBuyPant := ["재단지침서1","재단지침서2","재단지침서3","재단지침서4","하늘색","연두색","황토색","보라색","분홍색","자주색","검정색","연자색","주황색","군청색","파랑색","노란색","연갈색","빨간색","하얀색"]
Global AutoBuyNeckla := ["루비넥","사파이어넥"]
Loop, %Category_Count% {
Category_Key := A_Index
Category_Value := Category[Category_Key]
Temp_Variable := Category_Value
%Temp_Variable%_Count := 0
for key, value in %Temp_Variable%
%Temp_Variable%_Count++
}
Return
LoadData:
gosub, Setting_Values
IfExist %A_ScriptName%.ini
{
Loop, %Category_Count% {
Category_Key := A_Index
Category_Value := Category[Category_Key]
Temp_Variable := Category_Value
Temp_Count := 0
for key, value in %Temp_Variable%
Temp_Count++
Loop, %Temp_Count% {
Temp_Key := A_Index
Temp_Value := %Temp_Variable%[Temp_Key]
Temp_Variable_Child := %Temp_Value%
if(Category_Value = "wanteditems"||Category_Value = "Mines"||Category_Value = "AutoBuyItem"||Category_Value = "AutoBuyInk"||Category_Value = "AutoBuyPant"||Category_Value = "AutoBuyNeckla")
IniRead, %Temp_Variable%%Temp_Value%, %A_ScriptName%.ini, %Temp_Variable%, %Temp_Value%
else
IniRead, %Temp_Value%, %A_ScriptName%.ini, %Temp_Variable%, %Temp_Value%
}
}
}
else{
Loop, %Category_Count% {
Category_Key := A_Index
Category_Value := Category[Category_Key]
Temp_Variable := Category_Value
Temp_Count := 0
for key, value in %Temp_Variable%
Temp_Count++
Loop, %Temp_Count% {
Temp_Key := A_Index
Temp_Value := %Temp_Variable%[Temp_Key]
Temp_Variable_Child := %Temp_Value%
if(Category_Value = "wanteditems"||Category_Value = "Mines"||Category_Value = "AutoBuyItem"||Category_Value = "AutoBuyInk"||Category_Value = "AutoBuyPant"||Category_Value = "AutoBuyNeckla")
%Temp_Variable%%Temp_Value% := 99
else
%Temp_Value% := 99
}
}
}
Return
SaveData:
Gui, Submit, Nohide
gosub, Setting_Values
Loop, %Category_Count% {
Category_Key := A_Index
Category_Value := Category[Category_Key]
Temp_Variable := Category_Value
Temp_Count := 0
for key, value in %Temp_Variable%
Temp_Count++
Loop, %Temp_Count% {
Temp_Key := A_Index
Temp_Value := %Temp_Variable%[Temp_Key]
if(Category_Value = "wanteditems"||Category_Value = "Mines"||Category_Value = "AutoBuyItem"||Category_Value = "AutoBuyInk"||Category_Value = "AutoBuyPant"||Category_Value = "AutoBuyNeckla")
Temp_Variable_Child := %Category_Value%%Temp_Value%
else
Temp_Variable_Child := %Temp_Value%
IniWrite, %Temp_Variable_Child%, %A_ScriptName%.ini, %Temp_Variable%, %Temp_Value%
}
}
return
ShowGui:
Gui, Font, S8 Arial ,
Tab0_Name:= "Basic_Setting"
X_Align_Base := 10
X_Align_Step := 20
loop,6 {
X_Align_%A_index% := X_Align_Base + X_Align_Step * A_Index
}
Y_Align_Base := 5
Y_Align_Step := 23
loop,12 {
Y_Align_%A_index% := Y_Align_Base + Y_Align_Step * A_Index
}
if(Player1Title = 99)
Variable_Temp := WindowTitle1
if(Player1Title != 99)
Variable_Temp := Player1Title
Gui, Add, DropDownList, x%X_Align_Base% y%Y_Align_Base%+1 w84 h130 +gReselectWinTitle vPlayer1Title choose1, %Variable_Temp%
Loop, %jElancia_Count%{
temp_Variable := WindowTitle%A_Index%
if(Variable_Temp!=temp_Variable)
GuiControl,, Player1Title, %temp_Variable%
}
Mode_kinds := ["상태체크","광물캐기","자사먹자","길탐수련","밥통작","겜섬오토","염약구매","바지구매","포남링교환","무바","멈가수련"]
Mode_kinds_Count := 0
for key, value in Mode_kinds
Mode_kinds_Count++
if(Mode != 99)
Variable_Temp := Mode
else
Variable_Temp := "상태체크"
Gui, Add, DropDownList, x%X_Align_Base% y%Y_Align_1% w84 h130 vMode choose1, %Variable_Temp%
Loop, %Mode_kinds_Count%{
Key := A_Index
temp_Variable := Mode_kinds[Key]
if(Variable_Temp!=temp_Variable)
GuiControl,, Mode, %temp_Variable%
}
Gui, Add, Button, x95 y%Y_Align_Base%-3 w74 h17 gRefleshWindowList1,새로고침
Gui, Add, Button, x95 y%Y_Align_1%-3 w36 h17 gRun_this, 시작
Gui, Add, Button, x133 y%Y_Align_1%-3 w36 h17 gStop_this, 중지
Gui, Add, Text, x%X_Align_Base% y%Y_Align_2% w164 h20 BackgroundTrans vCharLocation, 위치 :
Gui, Add, Text, x%X_Align_Base% y%Y_Align_3% w164 h20 BackgroundTrans vCharCurrentPos, 좌표 :
Gui, Add, Text, x%X_Align_Base% y%Y_Align_4% w164 h20 BackgroundTrans vCharCurrentHP cRed, HP :
if (critical_hppercent!=99)
Variable_Temp := critical_hppercent / 10
else
Variable_Temp := 5
Gui, Add, DropDownList, x%X_Align_1% y%Y_Align_5% w38 h60 choose1 +gSettingChanged vcritical_hppercent choose%Variable_Temp%,10|20|30|40|50|60|70|80|90
if (hpshortcut=99||hpshortcut="안함")
Variable_Temp := 11
else if (hpshortcut=0)
Variable_Temp := 10
else
Variable_Temp := hpshortcut
Gui, Add, DropDownList, x%X_Align_6% y%Y_Align_5% w40 h100 choose1 +gSettingChanged vhpshortcut choose%Variable_Temp%,1|2|3|4|5|6|7|8|9|0|안함
Gui, Add, Text, x%X_Align_Base% y%Y_Align_6% w164 h20 BackgroundTrans vCharCurrentmp cBlue, MP :
if (critical_mppercent!=99)
Variable_Temp := critical_mppercent / 10
else
Variable_Temp := 5
Gui, Add, DropDownList, x%X_Align_1% y%Y_Align_7% w38 h60 choose1 +gSettingChanged vcritical_mppercent choose%Variable_Temp%,10|20|30|40|50|60|70|80|90
if (mpshortcut=99||mpshortcut="안함")
Variable_Temp := 11
else if (mpshortcut=0)
Variable_Temp := 10
else
Variable_Temp := mpshortcut
Gui, Add, DropDownList, x%X_Align_6% y%Y_Align_7% w40 h100 choose1 +gSettingChanged vmpshortcut choose%Variable_Temp%,1|2|3|4|5|6|7|8|9|0|안함
Gui, Add, Text, x%X_Align_Base% y%Y_Align_8% w164 h20 BackgroundTrans vCharCurrentfp cGreen, FP :
if (critical_fppercent!=99)
Variable_Temp := critical_fppercent / 10
else
Variable_Temp := 5
Gui, Add, DropDownList, x%X_Align_1% y%Y_Align_9% w38 h60 choose1 +gSettingChanged vcritical_fppercent choose%Variable_Temp%,10|20|30|40|50|60|70|80|90
Y_Align_5 := Y_Align_5+2
Gui, Add, Text, x%X_Align_Base% y%Y_Align_5% BackgroundTrans, hp
Gui, Add, Text, x%X_Align_3% y%Y_Align_5% BackgroundTrans, `% 이하`,클릭
Gui, Add, Text, x%X_Align_Base% y%Y_Align_7% BackgroundTrans, mp
Gui, Add, Text, x%X_Align_3% y%Y_Align_7% BackgroundTrans, `% 이하`,클릭
Gui, Add, Text, x%X_Align_Base% y%Y_Align_9% BackgroundTrans, fp
Gui, Add, Text, x%X_Align_3% y%Y_Align_9% BackgroundTrans, `% 이하`,클릭
if (fpshortcut=99||fpshortcut="안함")
Variable_Temp := 11
else if (fpshortcut=0)
Variable_Temp := 10
else
Variable_Temp := fpshortcut
Gui, Add, DropDownList, x%X_Align_6% y%Y_Align_9%-5 w40 h100 choose1 +gSettingChanged vfpshortcut choose%Variable_Temp%,1|2|3|4|5|6|7|8|9|0|안함
Gui, Add, Text, x5 y%Y_Align_10% w154 BackgroundTrans vCharCurrentGalid ,소지금 :
Gui, Add, Text, x5 y%Y_Align_11% w154 BackgroundTrans vCharCurrentItem, 아이템칸 :
Gui, Add, Text, x5 y%Y_Align_12% w30 h20 ,대화:
Gui, Add, Text, x91 y%Y_Align_12% w30 h20 ,명상:
Y_Align_12 := Y_Align_12-2
if (talk=0)
Variable_Temp := 10
else if (talk!=99)
Variable_Temp := talk
else
Variable_Temp := 1
Gui, Add, DropDownList, x35 y%Y_Align_12% w35 h100 BackgroundTrans +gSettingChanged vtalk choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(Cheese_Select = 1)
Gui, Add, Checkbox, x72 y%Y_Align_12% w15 h15 +gSettingChanged vtalk_Select checked,
else
Gui, Add, Checkbox, x72 y%Y_Align_12% w15 h15 +gSettingChanged vtalk_Select,
if (meditation=0)
Variable_Temp := 10
else if (meditation!=99)
Variable_Temp := meditation
else
Variable_Temp := 1
Gui, Add, DropDownList, x122 y%Y_Align_12% w35 h100 BackgroundTrans +gSettingChanged vmeditation choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(meditation_Select = 1)
Gui, Add, Checkbox, x159 y%Y_Align_12% w15 h15 +gSettingChanged vmeditation_Select checked,
else
Gui, Add, Checkbox, x159 y%Y_Align_12% w15 h15 +gSettingChanged vmeditation_Select,
Gui, Add, Text, x5 y320 w470 h40 BackgroundTrans vStatusline, 상태표시줄: [대기중]
Gui, Color, FFFFFF
Gui, Add, Tab3, vTab2 x530 y10 w200 h270, 요리재료|염색약|바지|넥클리스
Sub_Category_1 := ["AutoBuyItem","AutoBuyInk","AutoBuyPant","AutoBuyNeckla"]
loop,4 {
Key := A_Index
Gui, Tab, %Key%
5x_base := 450
5x_step := 91
5y_base := 32 + 20
5y_step := 20
temp_X := 5x_base
temp_Y := 5y_base
tabname := Sub_Category_1[Key]
temp_count := %tabname%_Count
A := 1
Loop, %temp_count%
{
Value := %tabname%[A_Index]
if (Mod(A_Index-1, 11) = 0){
temp_X := temp_X + 5x_step
temp_Y := 5y_base
}
if (%tabname%%Value% = 1) {
Gui, Add, Checkbox, x%temp_X% y%temp_Y% w90 h20 +gSettingChanged v%tabname%%Value% checked, %Value%
}
else if (%tabname%%Value% != 1) {
Gui, Add, Checkbox, x%temp_X% y%temp_Y% w90 h20 +gSettingChanged v%tabname%%Value%, %Value%
}
temp_Y := temp_Y + 5y_step
}
}
Gui, Add, Tab3, vTab3 x530 y10 w200 h270, 상태체크
gui, tab, 1
y_base := 48
x_base := 450
x_base2 := 210
x_base3 := 541
loop, 10 {
A:=A_INDEX
Gui, Add, text, x%x_base3% y%y_base% w180 h22 vPlayer%A%status,
y_base := y_base + 23
}
gui, tab, 2
y_base := 48+4
x_base := 450
x_base2 := 210
x_base3 := 541
x_base4 := x_base3+92
loop, 10 {
A:=A_INDEX
if(Southern_Exc1_Player%A%_check = 99||Southern_Exc1_Player%A%_check = 0)
Gui, Add, checkbox, x%x_base3% y%y_base% w80 h15 vSouthern_Exc1_Player%A%_check, 링 교환
else
Gui, Add, checkbox, x%x_base3% y%y_base% w80 h15 vSouthern_Exc1_Player%A%_check checked, 링 교환
if(Southern_Exc2_Player%A%_check = 99||Southern_Exc2_Player%A%_check = 0)
Gui, Add, checkbox, x%x_base4% y%y_base% w80 h15 vSouthern_Exc2_Player%A%_check, 정수 교환
else
Gui, Add, checkbox, x%x_base4% y%y_base% w80 h15 vSouthern_Exc2_Player%A%_check checked, 정수 교환
y_base := y_base + 23
}
gui, tab, 3
y_base := 48+4
x_base := 450
x_base2 := 210
x_base3 := 541
x_base4 := x_base3+82
x_base5 := x_base4+52
loop, 10 {
A:=A_INDEX
if(Gamble_Exc1_Player%A%_check = 99||Gamble_Exc1_Player%A%_check = 0)
Gui, Add, checkbox, x%x_base3% y%y_base% w80 h15 vGamble_Exc1_Player%A%_check, 정보 교환
else
Gui, Add, checkbox, x%x_base3% y%y_base% w80 h15 vGamble_Exc1_Player%A%_check checked, 정보 교환
Gui, Add, text, x%x_base4% y%y_base% w50 h15 , 정눈 갯수:
Gui, Add, edit, x%x_base5% y%y_base% w40 h15 vGamble_Exc1_Player%A%_count,
y_base := y_base + 23
}
Gui, Add, Tab3, vTab4 x530 y10 w200 h270, 파티설정|원격NPC|어빌체크
gui, tab, 1
y_base := 47
x_base := 541
x_base2 := x_base+20
x_base3 := x_base2+90
loop, 7 {
A:=A_INDEX
if(partyPlayer%A%Title = 99)
Variable_Temp := WindowTitle%A%
else if(partyPlayer%A%Title != 99)
Variable_Temp := partyPlayer%A%Title
if(A!=1)
{
if(partyPlayer%A%Title_Selected = 1)
Gui, Add, CheckBox, x%x_base% y%y_base% w15 h15 vpartyPlayer%A%Title_Selected checked,
else if(partyPlayer%A%Title_Selected != 1)
Gui, Add, CheckBox, x%x_base% y%y_base% w15 h15 vpartyPlayer%A%Title_Selected,
}
Gui, Add, DropDownList, x%x_base2% y%y_base% w84 h130 +gReselectWinTitle vpartyPlayer%A%Title choose1, %Variable_Temp%
Loop, %jElancia_Count%{
temp_Variable := WindowTitle%A_Index%
if(Variable_Temp!=temp_Variable)
GuiControl,, partyPlayer%A%Title, %temp_Variable%
}
y_base := y_base + 25
}
Gui, Add, Button, x%x_base2% y%y_base% w84 h20 g파티, 파티맺기
y_base := y_base + 20
Gui, Add, Button, x%x_base2% y%y_base% w84 h20 gRefleshWindowList2, 새로고침
gui, tab, 2
y_base := 97
x_base := 541-20+5
x_base2 := x_base+10
x_base3 := x_base2+90
x_base4 := x_base3+68
Gui, Add, text, x%x_base2% y%y_base%, 클릭한 NPC
Gui, Add, edit, x%x_base3% y%y_base% w60 vLatestNPCID,
y_base := y_base +20
Gui, Add, text, x%x_base2% y%y_base%, 현재 설정값
Gui, Add, edit, x%x_base3% y%y_base% w60 vNPCID,
Gui, Add, Button, x%x_base4% y%y_base% w33 grun_npcid,호출
Gui, Add, Button, x%x_base4% y65 w33 gstop_npcid,중지
y_base := y_base +30
Gui, Add, ListView, x%x_base2% y%y_base% r20 h100 w190 vnpcidlist gNPCLIST +altsubmit, 차원|NPC이름|NPCID
y_base := y_base +105
Gui, Add, Button, x%x_base2% y%y_base% h20 w40 gADD,추가
x_base2:=x_base2+42
Gui, Add, Button, x%x_base2% y%y_base% h20 w40 gMODIFYx,수정
x_base2:=x_base2+42
Gui, Add, Button, x%x_base2% y%y_base% h20 w40 gDELETEx,삭제
x_base5 := x_base2 + 46
Gui, Add, Button, x%x_base5% y%y_base% h20 w60 gGet_NPCID_from_web,서버접속
npcidinifile:= a_scriptdir . "\npcid.ini"
LV_ModifyCol(2,70)
LV_ModifyCol(3,70)
gui, tab, 3
y_base := 47
x_base := 541-20+5 +10
Gui, Add, ListView, x%x_base% y%y_base% r20 h180 w190 vabilitylist , 이름|그렐|어빌리티
loop,50
{
A:=4*A_index
Skill%A_index%_Name := ReadMemorytxt(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD4) +0x178) +0xc6) +0x8) +A) +0x8) +0x4)
Skill%A_index%_G := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x20c)
Skill%A_index% := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x208)
target := Skill%A_index%_Name
grade := Skill%A_index%_G
number := Skill%A_index%
number := round(number/100,2)
if(target!=Fail)
LV_Add("", target, grade, number)
}
LV_ModifyCol(1,65)
LV_ModifyCol(2,30)
LV_ModifyCol(3,70)
Gui, Add, Tab2, +Theme vTab1 gTab1 x175 y2 w330 h315 , 멈가세팅|단체활동|사냥보조|자동구매|광물캐기|자사먹자|낚시먹자|길탐배달|무바설정|기타설정
gui, tab, 10
x_temp:=190
y_temp:=47
y_temp_:=y_temp-2
x_temp1:=x_temp+75
x_temp2:=x_temp+95
x_temp3:=x_temp2+95
y_temp1:=y_temp+25
y_temp1_:=y_temp1-2
loop,8{
Temp:=A_Index+1
y_temp%Temp% := y_temp%A_Index%+25
y_temp%Temp%_ := y_temp%Temp%-2
}
Gui, Add, Text,  x%x_temp% y%y_temp% w100 h20 , 해상도 설정
Gui, Add, Button, x%x_temp% y%y_temp1% w84 h20 gSettingto800, 800x600
Gui, Add, Button, x%x_temp% y%y_temp2% w84 h20 gSettingto1200, 1200x900
Gui, Add, Button, x%x_temp% y%y_temp3% w84 h20 gSettingto1600, 1600x1200
Gui, Add, Text,  x%x_temp% y%y_temp4% w90 h20 , 인게임 핵 테스트
Gui, Add, Checkbox, x%x_temp% y%y_temp5% w84 h20 +gfreezehack vfreezehack_check, 이동
Gui, Add, Checkbox, x%x_temp% y%y_temp6% w84 h20 +gwallhack vwallhack_check, 벽
Gui, Add, Checkbox, x%x_temp% y%y_temp7% w84 h20 +gcharhack vcharhack_check, 캐릭
Gui, Add, Checkbox, x%x_temp% y%y_temp8% w84 h20 +gfloorhack vfloorhack_check, 바닥
gui, tab, 3
gui, tab, 1
Bread_Sellers_list := ["카딜라","샤네트","카레푸","오이피노","쿠키","베스"]
Bread_Sellers_list_Count := 0
for key, value in Bread_Sellers_list
Bread_Sellers_list_Count++
if(Bread_Sellers = 99)
Variable_Temp := "카딜라"
else
Variable_Temp := Bread_Sellers
x_temp:=190
x_G := 190-5
x_G2 := x_G+165-5
y_G := 72-20
y_G2 :=72+25+25+25+25+25+5
y_temp:=72
y_temp_:=y_temp-2
x_temp1:=x_temp+75
x_temp2:=x_temp+130
x_temp3:= x_temp+160
x_temp4:=x_temp3+75
x_temp5:=x_temp3+130
y_temp1:=y_temp+25
y_temp1_:=y_temp1-2
loop,8{
Temp:=A_Index+1
y_temp%Temp% := y_temp%A_Index%+25
y_temp%Temp%_ := y_temp%Temp%-2
}
Gui, Add, GroupBox, r7 x%x_G% y%y_G% w155 Section, 길탐수련 설정
Gui, Add, Text, x%x_temp% y%y_temp% w84 h20 ,음식 판매자:
Gui, Add, Text, x%x_temp% y%y_temp1% w84 h20 ,식빵 단축키:
if(Bread_Select = 1)
Gui, Add, Checkbox, x%x_temp2% y%y_temp1_% w15 h15 +gSettingChanged vBread_Select checked,
else
Gui, Add, Checkbox, x%x_temp2% y%y_temp1_% w15 h15 +gSettingChanged vBread_Select,
Gui, Add, Text, x%x_temp% y%y_temp2% w84 h20 ,치즈 단축키:
if(Cheese_Select = 1)
Gui, Add, Checkbox, x%x_temp2% y%y_temp2_% w15 h15 +gSettingChanged vCheese_Select checked,
else
Gui, Add, Checkbox, x%x_temp2% y%y_temp2_% w15 h15 +gSettingChanged vCheese_Select,
Gui, Add, Text, x%x_temp% y%y_temp3% w84 h20 ,길탐책 단축키:
Gui, Add, Text, x%x_temp% y%y_temp4% w84 h20 ,길탐 딜레이:
Gui, Add, Text, x%x_temp2% y%y_temp4% w15 h20 ,ms
Gui, Add, DropDownList, x%x_temp1% y%y_temp_% w70 h130 vBread_Sellers choose1, %Variable_Temp%
Loop, %Bread_Sellers_list_Count%{
Key := A_Index
temp_Variable := Bread_Sellers_list[Key]
if(Variable_Temp!=temp_Variable)
GuiControl,, Bread_Sellers, %temp_Variable%
}
textwidth := 45
textwidth_double := 55
textheight := 15
if (BreadShortCut=0)
Variable_Temp := 10
else if (BreadShortCut!=99)
Variable_Temp := BreadShortCut
else
Variable_Temp := 7
Gui, Add, DropDownList, x%x_temp1% y%y_temp1_% w%textwidth% h100 BackgroundTrans +gSettingChanged  vBreadShortCut choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if (CheaseShortCut=0)
Variable_Temp := 10
else if (CheaseShortCut!=99)
Variable_Temp := CheaseShortCut
else
Variable_Temp := 8
Gui, Add, DropDownList, x%x_temp1% y%y_temp2_% w%textwidth% h100 BackgroundTrans +gSettingChanged vCheaseShortCut choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if (Book=0)
Variable_Temp := 10
else if (Book!=99)
Variable_Temp := Book
else
Variable_Temp := 6
Gui, Add, DropDownList, x%x_temp1% y%y_temp3_% w%textwidth% h100 BackgroundTrans +gSettingChanged vBook choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if (SearchMoveDelay!=99)
Variable_Temp := SearchMoveDelay
else
Variable_Temp := 1500
Gui, Add, Edit, x%x_temp1% y%y_temp4_% w%textwidth% h%textheight% BackgroundTrans +gSettingChanged vSearchMoveDelay, %variable_temp%
Gui, Add, GroupBox, r5 x%x_G% y%y_G2% w155 Section, 음유/정술 설정
Gui, Add, GroupBox, r7 x%x_G2% y%y_G% w155 Section, 멈가수련 설정
Gui, Add, Text, x%x_temp3% y%y_temp% w84 h20 ,장비 단축키:
if (robweapon=0)
Variable_Temp := 10
else if (robweapon!=99)
Variable_Temp := robweapon
else
Variable_Temp := 1
Gui, Add, DropDownList, x%x_temp4% y%y_temp_% w%textwidth% h100 BackgroundTrans +gSettingChanged vrobweapon choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(robweapon_Select = 1)
Gui, Add, Checkbox, x%x_temp5% y%y_temp% w15 h15 +gSettingChanged vrobweapon_Select checked,
else
Gui, Add, Checkbox, x%x_temp5% y%y_temp% w15 h15 +gSettingChanged vrobweapon_Select,
Gui, Add, Text, x%x_temp3% y%y_temp1% w84 h20, 훔치기 단축키:
if (rob=0)
Variable_Temp := 10
else if (rob!=99)
Variable_Temp := rob
else
Variable_Temp := 2
Gui, Add, DropDownList, x%x_temp4% y%y_temp1_% w%textwidth% h100 BackgroundTrans +gSettingChanged vrob choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(rob_Select = 1)
Gui, Add, Checkbox, x%x_temp5% y%y_temp1% w15 h15 +gSettingChanged vrob_Select checked,
else
Gui, Add, Checkbox, x%x_temp5% y%y_temp1% w15 h15 +gSettingChanged vrob_Select,
Gui, Add, Text, x%x_temp3% y%y_temp2% w84 h20 ,훔쳐보 단축키:
if (rob2=0)
Variable_Temp := 10
else if (rob2!=99)
Variable_Temp := rob2
else
Variable_Temp := 3
Gui, Add, DropDownList, x%x_temp4% y%y_temp2_% w%textwidth% h100 BackgroundTrans +gSettingChanged vrob2 choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(rob2_Select = 1)
Gui, Add, Checkbox, x%x_temp5% y%y_temp2% w15 h15 +gSettingChanged vrob2_Select checked,
else
Gui, Add, Checkbox, x%x_temp5% y%y_temp2% w15 h15 +gSettingChanged vrob2_Select,
Gui, Add, Text, x%x_temp3% y%y_temp3% w84 h20 ,센스 단축키:
if (rob3=0)
Variable_Temp := 10
else if (rob3!=99)
Variable_Temp := rob3
else
Variable_Temp := 4
Gui, Add, DropDownList, x%x_temp4% y%y_temp3_% w%textwidth% h100 BackgroundTrans +gSettingChanged vrob3 choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
if(rob3_Select = 1)
Gui, Add, Checkbox, x%x_temp5% y%y_temp3% w15 h15 +gSettingChanged vrob3_Select checked,
else
Gui, Add, Checkbox, x%x_temp5% y%y_temp3% w15 h15 +gSettingChanged vrob3_Select,
Gui, Add, Text, x%x_temp3% y%y_temp4% w84 h20 ,타겟 위치:
if (rob_target_x!=99)
Variable_Temp := rob_target_x
else
Variable_Temp := 395
Gui, Add, Edit, x%x_temp4% y%y_temp4_% w33 h%textheight% BackgroundTrans +gSettingChanged vrob_target_x, %variable_temp%
x_temp4 := x_temp4 +35
if (rob_target_y!=99)
Variable_Temp := rob_target_y
else
Variable_Temp := 220
Gui, Add, Edit, x%x_temp4% y%y_temp4_% w33 h%textheight% BackgroundTrans +gSettingChanged vrob_target_y, %variable_temp%
Gui, Add, GroupBox, r5 x%x_G2% y%y_G2% w155 Section, 수리 설정
Gui, Add, Text, x%x_temp3% y%y_temp6% w84 h20 ,수리소야 위치:
Gui, Add, Text, x%x_temp3% y%y_temp7% w84 h20 ,수리소야 순서:
Gui, Add, Text, x%x_temp3% y%y_temp8% w84 h20 ,수리장비 수량:
if (soya_x!=99)
Variable_Temp := soya_x
else
Variable_Temp := 324
x_temp4 := x_temp4 -35
Gui, Add, Edit, x%x_temp4% y%y_temp6_% w33 h%textheight% BackgroundTrans +gSettingChanged vsoya_x, %variable_temp%
x_temp4 := x_temp4 +35
if (soya_y!=99)
Variable_Temp := soya_y
else
Variable_Temp := 383
Gui, Add, Edit, x%x_temp4% y%y_temp6_% w33 h%textheight% BackgroundTrans +gSettingChanged vsoya_y, %variable_temp%
if (soya_n!=99)
Variable_Temp := soya_n
else
Variable_Temp := 2
x_temp4 := x_temp4 -35
Gui, Add, Edit, x%x_temp4% y%y_temp7_% w33 h%textheight% BackgroundTrans +gSettingChanged vsoya_n, %variable_temp%
if (soya_c!=99)
Variable_Temp := soya_c
else
Variable_Temp := 5
Gui, Add, Edit, x%x_temp4% y%y_temp8_% w33 h%textheight% BackgroundTrans +gSettingChanged vsoya_c, %variable_temp%
gui, tab, 2
y_base := 47+10+10+10+4
x_base := 190
x_base2 := 210
x_base3 := 300
loop, 10 {
A:=A_INDEX
if(Player%A%Title = 99)
Variable_Temp := WindowTitle%A%
else if(Player%A%Title != 99)
Variable_Temp := Player%A%Title
if(Player%A%Title_Selected = 1)
Gui, Add, CheckBox, x%x_base% y%y_base% w15 h15 vPlayer%A%Title_Selected checked,
else if(A=1&&Player%A%Title = 99)
Gui, Add, CheckBox, x%x_base% y%y_base% w15 h15 vPlayer%A%Title_Selected checked,
else if(Player%A%Title_Selected != 1)
Gui, Add, CheckBox, x%x_base% y%y_base% w15 h15 vPlayer%A%Title_Selected,
if(A!=1){
Gui, Add, DropDownList, x%x_base2% y%y_base% w84 h130 +gReselectWinTitle vPlayer%A%Title choose1, %Variable_Temp%
Loop, %jElancia_Count%{
temp_Variable := WindowTitle%A_Index%
if(Variable_Temp!=temp_Variable)
GuiControl,, Player%A%Title, %temp_Variable%
}
}
y_base := y_base + 23
}
A := 1
2x_base := 310
2x_step := 95
2y_base := 45
2y_step := 20
temp_X0 := 2x_base
temp_Y0 := 2y_base
loop, 5 {
old_num:= A_INDEX - 1
temp_X%A_INDEX% := temp_X%old_num% + 2x_step
temp_Y%A_INDEX% := temp_Y%old_num% + 2y_step
}
textw := 35
textww := 55
texth := 15
gui, tab, 9
x_temp:=190
y_temp:=47
y_temp_:=y_temp-2
x_temp1:=x_temp+75
x_temp2:=x_temp+130
y_temp1:=y_temp+25
y_temp1_:=y_temp1-2
loop,8{
Temp:=A_Index+1
y_temp%Temp% := y_temp%A_Index%+25
y_temp%Temp%_ := y_temp%Temp%-2
}
Weapon_Change_list := ["2무바","3무바","4무바","5무바"]
Weapon_Change_list_Count := 0
for key, value in Weapon_Change_list
Weapon_Change_list_Count++
if(Weapon_Change = 99)
Variable_Temp := "3무바"
else
Variable_Temp := Weapon_Change
Gui, Add, Text, x%x_temp% y%y_temp% w84 h20 ,무바:
Gui, Add, DropDownList, x%x_temp1% y%y_temp_% w%textwidth% h100 BackgroundTrans +gSettingChanged vWeapon_Change choose1, %Variable_Temp%
Loop, %Weapon_Change_list_Count%{
Key := A_Index
temp_Variable := Weapon_Change_list[Key]
if(Variable_Temp!=temp_Variable)
GuiControl,, Weapon_Change, %temp_Variable%
}
Gui, Add, Text, x%x_temp% y%y_temp1% w84 h20 , 벗 무바:
if(noweapon=99)
Gui, Add, CheckBox, x%x_temp1% y%y_temp1_% w%textwidth% h15 BackgroundTrans +gSettingChanged vnoweapon,
Else
Gui, Add, CheckBox, x%x_temp1% y%y_temp1_% w%textwidth% h15 BackgroundTrans +gSettingChanged vnoweapon checked,
y_temp1:=y_temp1+25
y_temp1_:=y_temp1-2
A:=1
loop, 5
{
Gui, Add, Text, x%x_temp% y%y_temp1% w84 h20 ,무기%A%:
if (Weapon%A%=0)
Variable_Temp := 10
else if (Weapon%A%!=99)
Variable_Temp := Weapon%A%
else
Variable_Temp := A
Gui, Add, DropDownList, x%x_temp1% y%y_temp1_% w%textwidth% h100 BackgroundTrans +gSettingChanged vWeapon%A% choose%Variable_Temp%, 1|2|3|4|5|6|7|8|9|0
y_temp1:=y_temp1+25
y_temp1_:=y_temp1-2
A++
}
textwidth := 45
textwidth_double := 55
textheight := 15
gui, tab, 4
x_temp:=190
y_temp:=47
y_temp_:=y_temp-2
x_temp1:=x_temp+20
loop,5{
Temp:=A_Index+1
x_temp%Temp% := x_temp%A_Index%+20
}
y_temp1:=y_temp+20
y_temp1_:=y_temp1-2
loop,5{
Temp:=A_Index+1
y_temp%Temp% := y_temp%A_Index%+25
y_temp%Temp%_ := y_temp%Temp%-2
}
InTab_Check_Menu := ["Mines","wanteditems"]
tabnumber := 5
loop,2 {
Key := A_Index
tabname := InTab_Check_Menu[Key]
gui, tab, %tabnumber%
5x_base := 310
5x_step := 95
5y_base := 45
5y_step := 20
temp_X := 5x_base
temp_Y := 5y_base
temp_count := %tabname%_Count
A := 1
Loop, %temp_count%
{
Value := %tabname%[A_Index]
if (Mod(A_Index, 14) = 0){
temp_X := temp_X + 5x_step
temp_Y := 5y_base
}
if (%tabname%%Value% = 1) {
Gui, Add, Checkbox, x%temp_X% y%temp_Y% w95 h20 +gSettingChanged v%tabname%%Value% checked, %Value%
}
else if (%tabname%%Value% != 1) {
Gui, Add, Checkbox, x%temp_X% y%temp_Y% w95 h20 +gSettingChanged v%tabname%%Value%, %Value%
}
temp_Y := temp_Y + 5y_step
}
tabnumber++
}
gui, tab, 5
x_temp:=190
y_temp:=42
y_temp_:=y_temp-2
x_temp1:=x_temp+20
loop,5{
Temp:=A_Index+1
x_temp%Temp% := x_temp%A_Index%+40
}
Y_Num := y_temp
Gui, Color, FFFFFF
if (guix < 1||guix > 10000)
guix := 1
if (guiy < 1 ||guiy > 10000)
guiy := 1
Gui, Add, StatusBar,, 상태바1
Gui, Show, w510 h350 x%guix% y%guiy%, %ThisWindowTitle%
SB_SetParts(100, 200, 210)
SB_SetIcon("Shell32.dll", 269, 1)
Menu, CMenu, Add,
Menu, CMenu, Add, ADD            , menuDo
Menu, CMenu, Add,
Menu, CMenu, Add,
Menu, CMenu, Add, MODIFY         , menuDo
Menu, CMenu, Add,
Menu, CMenu, Add,
Menu, CMenu, Add, DELETE         , menuDo
Menu, CMenu, Add,
Fill:
gui,listview,npcidlist
Gui,1:default
LV_Delete()
i:=0
GuiControl, -Redraw, npcidlist
Fileread,var, *P65001 %npcidinifile%
for x,y in strsplit(var,"`n","`r")
{
if Y=
continue
row := []
loop, parse, y,%dlm%
row.push(a_loopfield)
i++
LV_add("",row*)
}
GuiControl, +Redraw, npcidlist
Guicontrol,1:,total1,%i%
GuiControl,1:Focus,srch
Return
NPCID확인:
SetFormat,integer, H
npcid := get_lastclicknpc()
npcid := Format("0x{:08X}", npcid)
guicontrolget, LatestNPCID
if(LatestNPCID != npcid)
Guicontrol,, LatestNPCID, %npcid%
SetFormat,integer, d
return
NPCLIST:
gui,listview,npcidlist
RN:=LV_GetNext("C")
if (rn=0)
return
Row := A_EventInfo
LV_GetText(C1,row,1)
LV_GetText(C2,row,2)
LV_GetText(C3,row,3)
if (A_GuiEvent = "DoubleClick")
{
LV_GetText(NPCID, A_EventInfo, 3)
guicontrol, ,NPCID, %NPCID%
}
if A_GuiEvent = click
goto,menux
if A_GuiEvent = Rightclick
goto,menux
return
Get_NPCID_from_web:
urldownloadtofile, https://raw.githubusercontent.com/SuperPowerJ/H-Elancia/main/npcid, npcid.ini
gosub, Fill
return
menux:
if (rn=0)
return
MouseGetPos, musX, musY
Menu, CMenu, Show, %musX%,%musY%
return
menudo:
If (A_ThisMenuItem = "ADD")
gosub,ADD
If (A_ThisMenuItem = "DELETE")
gosub,DELETEx
If (A_ThisMenuItem = "MODIFY")
gosub,MODIFYx
return
Deletex:
Gui,ListView,npcidlist
cxx:="",RowNumber:=0,DeleteArray := []
Loop
{
RowNumber := LV_GetNext(RowNumber)
if not RowNumber
Break
LV_GetText(C1,rownumber,1)
LV_GetText(C2,rownumber,2)
LV_GetText(C3,rownumber,3)
DeleteArray[RowNumber] := "DEL"
}
msgbox, 262180,삭제 ,정말 삭제할까요 ?`n%c1%,%c2%,%c3%
ifmsgbox,NO
{
for index, in DeleteArray
LV_Modify(index, "-Select -Focus")
return
}
cxx=
GuiControl, -Redraw, npcidlist
for index, in DeleteArray
LV_Delete(index-A_Index+1)
GuiControl, +Redraw, npcidlist
listx=
ControlGet, Listx, List, , SysListView321,%mainwindowtitle%
stringreplace,listx,listx,`t,%dlm%,all
Filedelete,%npcidinifile%
fileappend,%listx%`r`n,%npcidinifile%,utf-8
listx:=""
Return
MODIFYx:
Gui,submit,nohide
Gui,ListView,npcidlist
Loop
{
RowNumber := LV_GetNext(RowNumber)
if not RowNumber
Break
LV_GetText(C1,rownumber,1)
LV_GetText(C2,rownumber,2)
LV_GetText(C3,rownumber,3)
}
Gui,3:Add,Text,   x10   y10  w80          , 차원
Gui,3:Add,Edit,   x80  y10  w100 h19 vA31,%C1%
Gui,3:Add,Text,   x10   y35 w80          , NPC이름
Gui,3:Add,Edit,   x80  y35 w100 h19 vA32,%C2%
Gui,3:Add,Text,   x10   y60 w80          , NPCID
Gui,3:Add,Edit,   x80  y60 w100 h19 vA33,%C3%
Gui,3:Add, Button,x70 y90 w50  h27, OK
WinGetPos, GuiX, GuiY, PosW, PosH, %ThisWindowTitle%
GuiX := GuiX + 250
GuiY := GuiY + 150
Gui,3:Show, x%GuiX% y%GuiY% w190 h130, 수정
GuiControl,3:Focus,A31
return
ADD:
Gui,submit,nohide
Gui,2:Add,Text,   x10  y10  w80          , 차원
Gui,2:Add,Edit,   x80  y10  w100 h19 vA21,
Gui,2:Add,Text,   x10  y35 w80          , NPC이름
Gui,2:Add,Edit,   x80  y35 w100 h19 vA22,
Gui,2:Add,Text,   x10  y60 w80          , NPCID
Gui,2:Add,Edit,   x80  y60 w100 h19 vA23,
Gui,2:Add, Button,x70 y90 w50  h27, OK
WinGetPos, GuiX, GuiY, PosW, PosH, %ThisWindowTitle%
GuiX := GuiX + 250
GuiY := GuiY + 150
Gui,2:Show, x%GuiX% y%GuiY% w190 h130, 추가
GuiControl,2:Focus,A21
return
2GuiClose:
2GuiEscape:
Gui,2: Destroy
return
2ButtonOK:
Gui,2:submit,nohide
if A21=
{
Gui,2: Destroy
return
}
FILEAPPEND, %A21%%dlm%%A22%%dlm%%A23%`r`n,%npcidinifile%,utf-8
Gui,2: Destroy
GoSub,Fill
return
3GuiClose:
3GuiEscape:
Gui,3: Destroy
return
3ButtonOK:
Gui,3:submit,nohide
FileRead,Filecontent,  *P65001 %npcidinifile%
FileDelete, %npcidinifile%
StringReplace, FileContent, FileContent,%C1%%dlm%%C2%%dlm%%C3%, %A31%%dlm%%A32%%dlm%%A33%
FileAppend, %FileContent%`r`n, %npcidinifile%,UTF-8
filecontent=
Gui,3:destroy
Gosub,Fill
return
Self_NPCID_Update:
WindowTitle := Player1Title
MapNumber := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
SetFormat,integer, H
newnpcid := get_lastclicknpc()
newnpcid := Format("0x{:08X}", newnpcid)
if(newnpcid != oldnpcid)
{
if(MapNumber=4005)
{
Dimension := Readmemory(Readmemory(0x0058EB1C) + 0x10A)
if(Dimension>20000)
CharDimen:="감마"
else if(Dimension>10000)
CharDimen:="베타"
else if(Dimension<10000)
CharDimen:="알파"
NPCMsg := Check_NPCMsg()
NPCMsg1 := Check_NPCMsg1()
IfInString,NPCMsg,[서쪽파수꾼]을 만나고 와. 우리 마법은 번갈아가면서 받아야 하거든.
NPCNAME := "동쪽파수꾼"
else IfInString,NPCMsg,어떻게 여기까지 왔니?
NPCNAME := "동쪽파수꾼"
else IfInString,NPCMsg,[동쪽파수꾼]을 만나고 와. 우리 마법은 번갈아가면서 받아야 하거든.
NPCNAME := "서쪽파수꾼"
else IfInString,NPCMsg,[동쪽파수꾼]도 아직 잘 지내나 보네.
NPCNAME := "서쪽파수꾼"
else IfInString,NPCMsg1,[서쪽파수꾼]을 만나고 와. 우리 마법은 번갈아가면서 받아야 하거든.
NPCNAME := "동쪽파수꾼"
else IfInString,NPCMsg1,어떻게 여기까지 왔니?
NPCNAME := "동쪽파수꾼"
else IfInString,NPCMsg1,[동쪽파수꾼]을 만나고 와. 우리 마법은 번갈아가면서 받아야 하거든.
NPCNAME := "서쪽파수꾼"
else IfInString,NPCMsg1,[동쪽파수꾼]도 아직 잘 지내나 보네.
NPCNAME := "서쪽파수꾼"
FILEAPPEND, %CharDimen%%dlm%%NPCNAME%%dlm%%newnpcid%`r`n,%npcidinifile%,utf-8
GoSub,Fill
}
}
oldnpcid := newnpcid
return
포남링교환:
Guicontrol,, Statusline, (STEP4001)
Gui, Submit, nohide
Loop, 10
{
Player%A_Index%Delay1 := A_TickCount
Player%A_Index%NPCFORM := 0
Player%A_Index%Step := 9
Player%A_Index%success_rate :=0
if(Player%A_Index%Title_Selected = 1){
WindowTitle:=Player%A_Index%Title
inven := get_inven()
if(inven>49){
MsgBox, %WindowTitle% 의 인벤토리를 두칸정도 비우고 다시 시작해 주세요
coin := 1
break
}
}
}
Guicontrol,, Statusline, (STEP4002)
loop, {
if Coin!=1
break
loop, 10
{
Step := Player%A_Index%Step
success_rate := Player%A_Index%success_rate
Gui, Submit, nohide
if Coin!=1
break
else if(Player%A_Index%Title_Selected = 1 && Player%A_Index%success_rate != 2){
WindowTitle := Player%A_Index%Title
currentplayer := A_Index
sleep,1
Delay := A_TickCount - Player%A_Index%Delay1
if (Delay >= 500) {
if Coin!=1
break
formNumber := Check_FormNumber()
NPCMsg := Check_NPCMsg()
sleep,1
if(step=9)
{
Freeze_Move()
if(formNumber != 81 &&formNumber != 85 && formNumber != 121)
{
IfWinExist, %WindowTitle%
{
IfWinNotActive, %WindowTitle%
{
WinActivate,%WindowTitle%
}
}
Send, !m
Sleep,200
ret := IME_CHECK(WindowTitle)
sleep,100
if (%ret% = 0)
{
send, {vk15sc138}
sleep, 100
}
send,flshdk{space}apsb{enter}
sleep,1000
loop,
{
keyclick("CTRL1")
Sleep,100
formNumber := Check_FormNumber()
if coin != 1
break
else if formNumber = 85
break
}
loop,
{
Guicontrol,, Statusline, (STEP187-01)
formNumber := Check_FormNumber()
sleep, 10
if coin != 1
break
else if formNumber = 85
{
x:=373
y:=339
postclick(x,y)
Player%A_Index%Step := 2
sleep,1000
break
}
else if formNumber = 121
{
Player%A_Index%Step := 2
break
}
}
}
else if(formNumber != 0){
IfInString,NPCMsg,어디보자
{
Guicontrol,, Statusline, (STEP4002-1) %WindowTitle% 어디보자 formNumber: %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 5
y:=temp.y - 5
postclick(x,y)
Player%A_Index%Step := 3
}
else IfInString,NPCMsg,30개 받을게
{
Guicontrol,, Statusline, (STEP4002-2) %WindowTitle% 30개 받을게 formNumber: %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 14
y:=temp.y + 17
postclick(x,y)
Player%A_Index%Step := 4
}
else IfInString,NPCMsg,모자란 것
{
Guicontrol,, Statusline, (STEP4002-3) %WindowTitle% 모자란 것 formNumber: %formNumber%
KeyClick(6)
sleep,100
}
else IfInString,NPCMsg,미안한데 아이템은
{
Guicontrol,, Statusline, (STEP4002-4) %WindowTitle% 미안한데 아이템은 formNumber: %formNumber%
KeyClick(6)
Player%A_Index%Step := 2
}
else IfInString,NPCMsg,가 나왔네
{
Guicontrol,, Statusline, (STEP4002-4) %WindowTitle% 가 나왔네 formNumber: %formNumber%
KeyClick(6)
Player%A_Index%Step := 2
}
else
{
Guicontrol,, Statusline, (STEP4002-ERROR) %WindowTitle% formNumber: %formNumber%	 NPCMsg: %PCMsg%
sleep, 1
}
}
}
else if(step=2)
{
IfInString,NPCMsg,어디보자
{
Guicontrol,, Statusline, (STEP4002-2) %WindowTitle% 어디보자 formNumber: %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 5
y:=temp.y - 5
postclick(x,y)
Player%A_Index%Step := 3
}
}
else if(step=3)
{
IfInString,NPCMsg,받을게
{
Guicontrol,, Statusline, (STEP4002-3) %WindowTitle% 30개 받을게 formNumber: %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 14
y:=temp.y + 17
postclick(x,y)
Player%A_Index%Step := 4
}
}
else if(step=4)
{
IfInString,NPCMsg,미안한데 아이템은
{
Guicontrol,, Statusline, (STEP4002-4) %WindowTitle% 미안한데 아이템은 formNumber: %formNumber%
KeyClick(6)
sleep,10
Player%A_Index%Step := 2
}
else IfInString,NPCMsg,가 나왔네
{
Guicontrol,, Statusline, (STEP4002-4) %WindowTitle% 가 나왔네 formNumber: %formNumber%
KeyClick(6)
sleep,10
Player%A_Index%Step := 2
success_rate++
}
else IfInString,NPCMsg,모자란 것
{
Guicontrol,, Statusline, (STEP4002-4) %WindowTitle% 모자란 것 formNumber: %formNumber%
KeyClick(6)
sleep,10
}
}
Player%A_Index%Delay1 := A_TickCount
}
}
}
}
Guicontrol,, Statusline, ()
Return
Step187:
Guicontrol,, Statusline, (STEP187)
WindowTitle := Player1Title
coin := 1
loop,
{
formNumber := Check_FormNumber()
Guicontrol,, Statusline, (STEP187-00) %formNumber%
sleep,10
if coin != 1
break
else if (formNumber = 0||formNumber = 192)
{
KeyClick("CTRL1")
sleep,1500
}
else if formNumber = 85
break
}
loop,
{
Guicontrol,, Statusline, (STEP187-01)
formNumber := Check_FormNumber()
sleep, 10
if coin != 1
break
else if formNumber = 85
{
x:=373
y:=339
postclick(x,y)
Guicontrol,, Statusline, (STEP187-01) POSTCLICK %X% %Y%
sleep,1000
}
else if formNumber = 121
break
}
Guicontrol,, Statusline, (STEP187-02)
loop,
{
formNumber := Check_FormNumber()
if coin != 1
break
loop,
{
if coin != 1
break
Guicontrol,, Statusline, (STEP187-1) %formNumber%
sleep,100
NPCMsg := Check_NPCMsg()
IfInString,NPCMsg,어디보자
break
}
formNumber := Check_FormNumber()
Guicontrol,, Statusline, (STEP187-2) %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 5
y:=temp.y - 5
postclick(x,y)
formNumber := Check_FormNumber()
Guicontrol,, Statusline, (STEP187-3) %formNumber%
sleep,100
loop,
{
if coin != 1
break
NPCMsg := Check_NPCMsg()
IfInString,NPCMsg,30개 받을게
break
}
formNumber := Check_FormNumber()
Guicontrol,, Statusline, (STEP187-4) %formNumber%
temp:=get_NPCTalk_cordi()
x:=temp.x - 14
y:=temp.y + 17
postclick(x,y)
Guicontrol,, Statusline, (STEP187-5) %formNumber%
loop,
{
NPCMsg := Check_NPCMsg()
if coin != 1
break
IfInString,NPCMsg,모자란 것
{
KeyClick(6)
sleep,100
coin:=0
break
}
IfInString,NPCMsg,미안한데 아이템은
{
KeyClick(6)
sleep,100
break
}
sleep,100
Guicontrol,, Statusline, (STEP187-6)
}
Guicontrol,, Statusline, (STEP187-END)
}
return
Tab1:
Gui, Submit, NoHide
if Tab1 = 단체활동
{
GuiControl, Move, Tab3, x300 y40
GuiControl, Move, Player1Title, x210 y81
}
else
{
GuiControl, Move, Tab3, x520 y40
GuiControl, Move, Player1Title, x10 y5
}
if Tab1 = 사냥보조
{
GuiControl, Move, Tab4, x300 y40
SetTimer, NPCID확인, 1000
SetTimer, Self_NPCID_Update, 1000
}
else
{
GuiControl, Move, Tab4, x520 y40
SetTimer, NPCID확인, off
SetTimer, Self_NPCID_Update, off
}
if Tab1 = 자동구매
GuiControl, Move, Tab2, x300 y40
else
GuiControl, Move, Tab2, x520 y40
WinSet, Redraw, , A
return
GuiClose:
WinGetPos, GuiX, GuiY, PosW, PosH, %ThisWindowTitle%
gosub, SaveData
ExitApp
return
Run_this:
Guicontrol,, Statusline, (STEP000)
Gui, Submit, nohide
WindowTitle := Player1Title
Global currentplayer := 1
A:=1
Coin:=1
sleep, 10
Global CharStatusCHeck_delay := A_TickCount
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 알파입구
{
AAI = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 알파동파
{
AAD = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 알파서파
{
AAS = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 베타입구
{
BAI = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 베타동파
{
BAD = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine,베타서파
{
BAS = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 감마입구
{
GAI = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 감마동파
{
GAD = %A_LoopReadLine%
break
}
}
Loop,Read, c:\log.txt
{
ifinstring, A_LoopReadLine, 감마서파
{
GAS = %A_LoopReadLine%
break
}
}
StringMid, AAI, AAI, 7, 11
StringMid, AAD, AAD, 7, 11
StringMid, AAS, AAS, 7, 11
StringMid, BAI, BAI, 7, 11
StringMid, BAD, BAD, 7, 11
StringMid, BAS, BAS, 7, 11
StringMid, GAI, GAI, 7, 11
StringMid, GAD, GAD, 7, 11
StringMid, GAS, GAS, 7, 11
Gosub, run_npcid
SetTimer, CharStatusCheck, 1000
Guicontrol,, Statusline, (STEP001)
sleep, 10
Guicontrol,, Statusline, (STEP002)
if(Coin!=1){
Guicontrol,, Statusline, (STEP000) 대기중
if(Mode="포남링교환"){
loop, 10
{
GuiControlGet,Player%A_Index%Title_Selected
if(Player%A_Index%Title_Selected = 1){
WindowTitle := Player%A_Index%Title
Un_Freeze_Move()
}
}
KeyClick("AltR")
return
}
}
else if(Mode="길탐수련"){
Guicontrol,, Statusline, (STEP101)
gosub, 길탐수련
}
else if(Mode="자사먹자"){
Guicontrol,, Statusline, (STEP601)
gosub, 자사먹자
}
else if(Mode="광물캐기"){
gosub, 광물캐기
Guicontrol,, Statusline, (STEP501)
}
else if(Mode="자동구매"){
gosub, 자동구매
Guicontrol,, Statusline, (STEP401-1)
}
else if(Mode="염약구매"){
gosub, 염약구매
Guicontrol,, Statusline, (STEP401-2)
}
else if(Mode="바지구매"){
gosub, 바지구매
Guicontrol,, Statusline, (STEP401-3)
}
else if(Mode="상태체크"){
gosub, 상태체크
Guicontrol,, Statusline, (STEP1001)
}
else if(Mode="밥통작"){
gosub, 밥통작
Guicontrol,, Statusline, (STEP3001)
}
else if(Mode="겜섬오토"){
gosub, 겜섬오토
Guicontrol,, Statusline, (STEP4001)
}
else if(Mode="포남링교환"){
gosub, 포남링교환
Guicontrol,, Statusline, (STEP5001)
}
else if(Mode="무바"){
gosub, 무바
Guicontrol,, Statusline, (STEP5001)
}
else if(Mode="멈가수련"){
gosub, 멈가수련
Guicontrol,, Statusline, (STEP5001)
}
if(Coin!=1){
Guicontrol,, Statusline, (STEP000) 대기중
if(Mode="포남링교환"){
loop, 10
{
GuiControlGet,Player%A_Index%Title_Selected
if(Player%A_Index%Title_Selected = 1){
WindowTitle := Player%A_Index%Title
Un_Freeze_Move()
}
}
}
KeyClick("AltR")
return
}
return
Stop_this:
Coin:=0
SetTimer, CharStatusCheck, off
return
CharStatusCheck:
if(Coin=1)
CharStatusCheck()
return
Search_Book1_1Clicked:
GuiControl,, Search_Book1_2, Disable
GuiControl,, Search_Book1_3, Disable
return
Search_Book1_2Clicked:
GuiControl,, Search_Book1_1, Disable
GuiControl,, Search_Book1_3, Disable
return
Search_Book1_3Clicked:
GuiControl,, Search_Book1_1, Disable
GuiControl,, Search_Book1_2, Disable
return
ReselectWinTitle:
WindowTitle := Player1Title
return
RefleshWindowList1:
gui,submit,nohide
WindowTitle:=Player1title
IfWinExist, %WindowTitle%
{
IfWinNotActive, %WindowTitle%
{
WinActivate,%WindowTitle%
}
}
loop,10
{
RefleshWindowList(A_INDEX)
}
return
RefleshWindowList2:
gui,submit,nohide
WindowTitle:=partyPlayer1title
IfWinExist, %WindowTitle%
{
IfWinNotActive, %WindowTitle%
{
WinActivate,%WindowTitle%
}
}
loop,7
{
RefleshPartyWindowList(A_INDEX)
}
return
freezehack:
Gui, Submit, nohide
WindowTitle := Player1Title
if freezehack_check = 1
Freeze_Move()
else if freezehack_check = 0
Un_Freeze_Move()
return
wallhack:
gui, submit, nohide
WindowTitle := Player1Title
if wallhack_check = 1
wall_remove_enable()
else if wallhack_check = 0
wall_remove_disable()
return
charhack:
gui, submit, nohide
WindowTitle := Player1Title
if wallhack_check = 1
char_remove_enable()
else if wallhack_check = 0
char_remove_disable()
return
floorhack:
gui, submit, nohide
WindowTitle := Player1Title
if wallhack_check = 1
floor_remove_enable()
else if wallhack_check = 0
floor_remove_disable()
return
상태체크:
Gui, Submit, nohide
Loop, 10
{
Player%A_Index%Delay1 := A_TickCount
Player%A_Index%Delay2 := A_TickCount
}
Guicontrol,, Statusline, (STEP1001)
loop, {
if Coin!=1
break
loop, 10
{
if Coin!=1
break
else if(Player%A_Index%Title_Selected = 1){
WindowTitle := Player%A_Index%Title
ride_enable()
currentplayer := A_Index
sleep,1
Delay := A_TickCount - Player%A_Index%Delay1
if (Delay >= 500) {
CharStatusCheck()
Player%A_Index%Delay1 := A_TickCount
Guicontrol,, Statusline, (STEP1001-1) %WindowTitle%
}
}
}
}
Guicontrol,, Statusline, (STEP3004)
return
밥통작:
Gui, Submit, nohide
Loop, 10
{
Player%A_Index%Delay1 := A_TickCount
Player%A_Index%Delay2 := A_TickCount
}
Guicontrol,, Statusline, (STEP3002)
loop, {
if Coin!=1
break
loop, 10
{
if Coin!=1
break
Guicontrol,, Statusline, (STEP3101)
if(Player%A_Index%Title_Selected = 1){
WindowTitle := Player%A_Index%Title
currentplayer := A_Index
sleep,1
Guicontrol,, Statusline, (STEP3101) %WindowTitle%
Delay := A_TickCount - Player%A_Index%Delay1
if (Delay >= 11000) {
KeyClick(1)
KeyClick(1)
KeyClick(1)
Player%A_Index%Delay1 := A_TickCount
}
formNumber := Check_FormNumber()
if(formNumber = 85)
KeyClick(6)
Guicontrol,, Statusline, (STEP3102) %WindowTitle% 1번키 클릭
Delay := A_TickCount - Player%A_Index%Delay2
if (Delay >= 60500) {
sleep, 1
KeyClick("CTRL1")
sleep, 100
KeyClick(6)
sleep, 100
KeyClick(6)
Player%A_Index%Delay2 := A_TickCount
Guicontrol,, Statusline, (STEP3202) %WindowTitle% CTRL1번키 후 6번키 클릭
}
if Coin!=1
break
}
}
}
Guicontrol,, Statusline, (STEP3004)
return
겜섬오토:
Gui, Submit, nohide
Loop, 10
{
if(Player%A_Index%Title_Selected = 1){
Player%A_Index%Delay1 := A_TickCount
Player%A_Index%Delay2 := A_TickCount
}
}
Guicontrol,, Statusline, (STEP4002)
loop, {
if Coin!=1
break
loop, 10
{
if Coin!=1
break
Guicontrol,, Statusline, (STEP4003)
Gui, Submit, nohide
sleep,1
if(Player%A_Index%Title_Selected = 1){
WindowTitle := Player%A_Index%Title
currentplayer := A_Index
sleep,1
if(presetting%A_Index% != 1){
SetTimer, CharStatusCheck, off
sleep,100
presetting := GameIslandMacroText()
sleep,100
presetting%A_Index% := 1
Guicontrol,, Statusline, (STEP4101)
SetTimer, CharStatusCheck, 1000
}
sleep,1
Guicontrol,, Statusline, (STEP4004) %WindowTitle%
Delay := A_TickCount - Player%A_Index%Delay1
if (Delay >= 1000) {
GameIslandMouseClickEvent()
Player%A_Index%Delay1 := A_TickCount
}
if Coin!=1
break
Delay := A_TickCount - Player%A_Index%Delay2
if (Delay >= 2000) {
GameIslandTextMacro()
Player%A_Index%Delay2 := A_TickCount
}
if Coin!=1
break
}
}
}
Guicontrol,, Statusline, (STEP3004)
return
길탐수련:
Gui, Submit, nohide
SetTimer, CharStatusCheck, off
Guicontrol,, Statusline, 상태표시줄:  [길탐수련] 시작준비중
WindowTitle := Player1Title
temp_check := Cheese_Select + bread_Select
if temp_check = 0
{
MsgBox, 식빵 치즈 둘중에 하나는 구매하도록 선택해야 합니다
Coin := 0
return
}
if(isFirstTimeRunThisCode := 1){
Guicontrol,, Statusline, (STEP102)
Freeze_Move()
wall_remove_enable()
floor_remove_enable()
char_remove_enable()
Move_Buy()
Move_Sell()
Move_Repair()
Buy_Unlimitted()
KeyClick("AltR")
if Bread_Sellers = 카딜라
NPCNAME := "zkelffk"
else if Bread_Sellers = 샤네트
NPCNAME := "tispxm"
else if Bread_Sellers = 카레푸
NPCNAME := "zkfpvn"
else if Bread_Sellers = 쿠키
NPCNAME := "znzl"
else if Bread_Sellers = 베스
NPCNAME := "qptm"
else if Bread_Sellers = 오이피노
NPCNAME := "dhdlvlsh"
Guicontrol,, Statusline, (STEP103) %Bread_Sellers%
inputmenu(NPCNAME)
isFirstTimeRunThisCode := 0
SearchRootCounter := A_TickCount
talkcounter := A_TickCount
sleep, 100
}
Guicontrol,, Statusline, (STEP105-0)상태표시줄:  [길탐수련] 작동중
loop,
{
if Coin!=1
break
if(FP.NOW <= 140){
Guicontrol,, Statusline, (STEP106-0)
loop,11{
if(Bread_Select = 1)
KeyClick(BreadShortCut)
if(Cheese_Select = 1)
KeyClick(CheaseShortCut)
FP := Get_FP()
if(FP.Now >= 140)
break
}
}
FP := Get_FP()
if(FP.NOW <= 80)
break
Delay := A_TickCount - talkcounter
if (Delay >= 100) {
if talk_check =1
keyclick(talk)
if meditation_check =1
keyclick(meditation)
CharStatusCheck()
talkcounter := A_TickCount
}
Delay := A_TickCount - SearchRootCounter
sleep,1
if (Delay >= SearchMoveDelay) {
Guicontrol,, Statusline, (STEP108-0)상태표시줄:  [길탐수련] 작동중
KeyClick(Book)
sleep,1
Num := 0
Search_Book(Num)
sleep,1
SearchRootCounter := A_TickCount
sleep,1
loop,50
{
A:=4*A_index
Skill%A_index%_Name := ReadMemorytxt(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD4) +0x178) +0xc6) +0x8) +A) +0x8) +0x4)
Skill%A_index%_G := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x20c)
Skill%A_index% := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x208)
}
loop, 50 {
target := Skill%A_index%_Name
number := Skill%A_index%
if (target = "길탐색")
{
if(number=10000)
{
SB_SetText("길탐색 어빌 100.00 달성, 작동중지", 3)
coin:=0
break
}
}
}
}
}
start_inven := Get_inven()
Guicontrol,, Statusline, (STEP105)상태표시줄:  [길탐수련] 작동중
loop,{
if Coin!=1
break
if (Get_inven() <= start_inven){
Guicontrol,, Statusline, (STEP105)상태표시줄:  [길탐수련] 작동중 - 식빵구매중
Galid := Get_Galid()
if (Galid <= 10000){
Guicontrol,, Statusline, (STEP104) %Galid%
MsgBox, 현재 소지 갈리드(%Galid%) 가 너무 적습니다.
break
}
BuyBread(Bread_Sellers,start_inven)
sleep,1
}
if(Check_Shop("Buy")!=0)
PostClick_Right_Menu()
if Coin!=1
break
FP := Get_FP()
if(FP.NOW <= 140){
Guicontrol,, Statusline, (STEP106)
loop,11{
if(Bread_Select = 1)
KeyClick(BreadShortCut)
if(Cheese_Select = 1)
KeyClick(CheaseShortCut)
FP := Get_FP()
if(FP.Now >= 140)
break
}
}
if Coin!=1
break
Guicontrol,, Statusline, (STEP107)상태표시줄:  [길탐수련] 작동중
Delay := A_TickCount - talkcounter
if (Delay >= 100) {
if talk_check =1
keyclick(talk)
if meditation_check =1
keyclick(meditation)
CharStatusCheck()
talkcounter := A_TickCount
}
Delay := A_TickCount - SearchRootCounter
sleep,1
if (Delay >= SearchMoveDelay) {
Guicontrol,, Statusline, (STEP108)상태표시줄:  [길탐수련] 작동중
KeyClick(Book)
sleep,1
Num := 0
Search_Book(Num)
sleep,1
SearchRootCounter := A_TickCount
sleep,1
loop,50
{
A:=4*A_index
Skill%A_index%_Name := ReadMemorytxt(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD4) +0x178) +0xc6) +0x8) +A) +0x8) +0x4)
Skill%A_index%_G := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x20c)
Skill%A_index% := Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(Readmemory(0x0058DAD4) +0x178) +0xc6) + 0x8) +A) +0x8) +0x208)
}
loop, 50 {
target := Skill%A_index%_Name
number := Skill%A_index%
if (target = "길탐색")
{
if(number=10000)
{
SB_SetText("길탐색 어빌 100.00 달성, 작동중지", 3)
coin:=0
break
}
}
}
}
}
Un_Freeze_Move()
wall_remove_disable()
char_remove_disable()
floor_remove_disable()
return
자동구매:
Gui, Submit, Nohide
if(isFirstTimeRunThisCode := 1){
Move_Buy()
Move_Sell()
Move_Repair()
Buy_Unlimitted()
inputallsellers("COOK")
start_inven := Get_inven()
isFirstTimeRunThisCode := 0
sleep, 100
}
Num:=1
loop,
{
Gui, Submit, nohide
if Coin!=1
break
Freeze_Move()
Move_buy()
MapNumber := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
if(MapNumber=3204){
loop,2 {
if Coin!=1
break
keyclick("CTRL7")
sleep, 1000
NPCMENUCLICK("Buy","CTRL7")
sleep, 200
loop, 5
{
if(Check_Shop("Buy")!=0)
break
else
{
sleep,1000
}
}
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
C3:="프랑크소시지"
C10:="식초"
C12:="유부"
C15:="후추"
C19:="밀가루반죽"
C25:="버터"
C26:="치즈"
C28:="식빵"
C29:="달걀"
C32:="쌀"
loop, 32 {
if Coin!=1
break
target := "C"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,2 {
PostClick_OK()
sleep,1000
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
loop,2 {
keyclick("CTRL8")
sleep, 1000
NPCMENUCLICK("Buy","CTRL8")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
D23:="식초"
D27:="후추"
D28:="간장"
D29:="마늘"
D33:="밀가루반죽"
D39:="버터"
D40:="치즈"
D42:="식빵"
D45:="쌀"
D46:="사과"
D57:="토마토"
D60:="당근"
D64:="감자"
D65:="빈병"
D66:="우유"
loop, 66 {
target := "D"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
else if(MapNumber=4200){
loop,2 {
if Coin!=1
break
keyclick("CTRL5")
sleep, 1000
NPCMENUCLICK("Buy","CTRL5")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
A17 := "고용서미피엘"
A18 := "고용서엘가노"
A19 := "고용서휘리스"
A20 := "고용서네시"
A21 := "고용서터그"
A22 := "고용서소야"
A23 := "식초"
A24 := "와사비"
A25 := "소금"
A26 := "설탕"
A27 := "후추"
A28 := "간장"
A29 := "마늘"
A30 := "마요네즈"
A31 := "바닐라향료"
A32 := "초컬릿반죽"
A33 := "밀가루반죽"
A34 := "카카오반죽"
A35 := "화이트소스"
A36 := "딸기쩀"
A37 := "크림"
A38 := "김"
A39 := "버터"
A40 := "치즈"
A41 := "참기름"
A42 := "식빵"
A43 := "스프가루"
A44 := "카레가루"
A45 := "쌀"
A46 := "사과"
A57 := "토마토"
A60 := "당근"
A61 := "딸기"
A64 := "감자"
A65 := "빈병"
A66 := "우유"
A72 := "스파게티면"
A73 := "다진소고기"
A74 := "올리브기름"
loop, 74 {
target := "A"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
loop,2 {
keyclick("CTRL6")
sleep, 1000
NPCMENUCLICK("Buy","CTRL6")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
B1:="닭고기"
B2:="햄"
B3:="프랑크소시지"
B4:="햄버그햄"
B5:="돼지고기조각"
B6:="돼지고기"
B7:="쇠고기조각"
B8:="싸움닭알"
B9:="미친닭앍"
B10:="식초"
B12:="유부"
B13:="소금"
B14:="설탕"
B15:="후추"
B18:="초컬릿반죽"
B19:="밀가루반죽"
B25:="버터"
B26:="치즈"
B28:="식빵"
B29:="달걀"
B32:="쌀"
loop, 32 {
target := "B"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
else if(MapNumber=1214){
Pos:=GetPos()
TempX := Pos.PosX
TempY := Pos.PosY
if(TempX >=26){
loop,2 {
if Coin!=1
break
keyclick("CTRL4")
sleep, 1000
NPCMENUCLICK("Buy","CTRL4")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
I1:="닭고기"
I2:="햄"
I3:="프랑크소시지"
I4:="햄버그햄"
I5:="돼지고기조각"
I10:="식초"
I11:="와사비"
I12:="소금"
I13:="설탕"
I14:="후추"
I17:="초컬릿반죽"
I18:="밀가루반죽"
I24:="버터"
I25:="치즈"
I26:="참기름"
I27:="식빵"
I28:="달걀"
I31:="쌀"
loop, 31 {
target := "I"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
Un_Freeze_Move()
loop, 10{
Click_CurrentMiniMapPos(-13,-13)
Sleep,1000
Pos:=GetPos()
TempX := Pos.PosX
TempY := Pos.PosY
if(TempX <= 24)
break
}
if(TempX <= 24){
loop,2 {
Freeze_Move()
keyclick("CTRL3")
sleep, 1000
NPCMENUCLICK("Buy","CTRL3")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
H24:="사과"
H35:="토마토"
H38:="당근"
H39:="딸기"
H42:="감자"
H43:="빈병"
H44:="우유"
loop, 44 {
target := "H"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
}
}
else if(MapNumber=204){
Pos:=GetPos()
TempX := Pos.PosX
TempY := Pos.PosY
if(TempY <=17){
loop,2 {
if Coin!=1
break
keyclick("CTRL1")
sleep, 1000
NPCMENUCLICK("Buy","CTRL1")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
E23:="식초"
E27:="후추"
E31:="밀가루반죽"
E37:="버터"
E38:="치즈"
E40:="식빵"
E43:="쌀"
loop, 43 {
target := "E"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
Un_Freeze_Move()
loop, 10{
Click_CurrentMiniMapPos(+13,+12)
Sleep,1000
Pos:=GetPos()
TempX := Pos.PosX
TempY := Pos.PosY
if(TempY >= 24)
break
}
if(TempY >= 24){
loop,2 {
if Coin!=1
break
Freeze_Move()
keyclick("CTRL2")
sleep, 1000
NPCMENUCLICK("Buy","CTRL2")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
G1:="사과"
G12:="토마토"
G15:="당근"
G19:="감자"
G20:="빈병"
G21:="우유"
loop, 21 {
target := "G"A_Index
target := %target%
target := AutoBuyItem%target%
if target = 1
loop,35{
keyclick("RightArrow")
}
sleep, 1
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
}
}
if Coin!=1
return
Temp:=Get_FP()
FPNow:=Temp.Now
FPMax:=Temp.Max
if FPNow <140
KeyClick(0)
inven := Get_inven()
if(inven>=49){
Freeze_Move()
sleep,1000
Search_Book(1)
sleep,3000
break
}
Num++
Search_Book(Num)
if Num=5
Num:=2
Sleep,3000
}
return
염약구매:
Gui, Submit, Nohide
Guicontrol,, Statusline, (STEP401-2)
if(isFirstTimeRunThisCode := 1){
Guicontrol,, Statusline, (STEP401-2-0)
Move_Buy()
Move_Sell()
Move_Repair()
Buy_Unlimitted()
inputallsellers("INK")
start_inven := Get_inven()
isFirstTimeRunThisCode := 0
sleep, 100
}
Num:=1
loop,
{
Guicontrol,, Statusline, (STEP401-2-1)
Gui, Submit, nohide
if Coin!=1
break
Freeze_Move()
Move_buy()
MapNumber := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
startinven := get_inven()
if(MapNumber=3216||MapNumber=2216){
Guicontrol,, Statusline, (STEP401-2-2-1)
loop,2 {
if Coin!=1
break
if MapNumber = 3216
{
keyclick("CTRL1")
sleep, 1000
NPCMENUCLICK("Buy","CTRL1")
}
else if MapNumber = 2216
{
keyclick("CTRL2")
sleep, 1000
NPCMENUCLICK("Buy","CTRL2")
}
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
SE7 := "지렁이병소"
SE8 := "지렁이병중"
SE9 := "지렁이병대"
SE17 := "하늘색"
SE18 := "연두색"
SE19 := "황토색"
SE20 := "보라색"
SE21 := "분홍색"
SE22 := "자주색"
SE23 := "검정색"
SE24 := "연자색"
SE25 := "주황색"
SE26 := "군청색"
SE27 := "파랑색"
SE28 := "노란색"
SE29 := "연갈색"
SE30 := "빨간색"
SE31 := "하얀색"
loop, 31 {
if Coin!=1
break
target := "SE"A_Index
target := %target%
target := AutoBuyInk%target%
if target = 1
loop,2{
keyclick("RightArrow")
}
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
else if(MapNumber=4216){
Guicontrol,, Statusline, (STEP401-2-2-2)
loop,2 {
if Coin!=1
break
keyclick("CTRL3")
sleep, 1000
NPCMENUCLICK("Buy","CTRL3")
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
CR7 := "지렁이병소"
CR8 := "지렁이병중"
CR9 := "지렁이병대"
CR20 := "하늘색"
CR21 := "연두색"
CR22 := "황토색"
CR23 := "보라색"
CR24 := "분홍색"
CR25 := "자주색"
CR26 := "검정색"
CR27 := "연자색"
CR28 := "주황색"
CR29 := "군청색"
CR30 := "파랑색"
CR31 := "노란색"
CR32 := "연갈색"
CR33 := "빨간색"
CR34 := "하얀색"
loop, 34 {
if Coin!=1
break
target := "CR"A_Index
target := %target%
target := AutoBuyInk%target%
if target = 1
loop,2{
keyclick("RightArrow")
}
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
if Coin!=1
return
Temp:=Get_FP()
FPNow:=Temp.Now
FPMax:=Temp.Max
if FPNow <140
KeyClick(0)
inven := Get_inven()
Guicontrol,, Statusline, (STEP401-2-3-1) start %startinven% now start %inven%
if(inven>=49){
Freeze_Move()
sleep,1000
Search_Book(1)
sleep,3000
break
}
if (startinven < inven)
{
Num++
Search_Book(Num)
}
if Num=3
Num:=2
Sleep,3000
}
return
바지구매:
Gui, Submit, Nohide
Guicontrol,, Statusline, (STEP401-3)
if(isFirstTimeRunThisCode := 1){
Guicontrol,, Statusline, (STEP401-3-0)
Move_Buy()
Move_Sell()
Move_Repair()
Buy_Unlimitted()
inputallsellers("PANT")
start_inven := Get_inven()
isFirstTimeRunThisCode := 0
sleep, 100
}
Num:=1
P1 := "재단지침서1"
P2 := "재단지침서2"
P3 := "재단지침서3"
P4 := "재단지침서3"
P5 := "하늘색"
P6 := "연두색"
P7 := "황토색"
P8 := "보라색"
P9 := "분홍색"
P10 := "자주색"
P11 := "검정색"
P12 := "연자색"
P13 := "주황색"
P14 := "군청색"
P15 := "파랑색"
P16 := "노란색"
P17 := "연갈색"
P18 := "빨간색"
P19 := "하얀색"
T16 := "하늘색"
T17 := "연두색"
T18 := "황토색"
T19 := "보라색"
T20 := "분홍색"
T21 := "자주색"
T22 := "검정색"
T23 := "연자색"
T24 := "주황색"
T25 := "군청색"
T26 := "파랑색"
T27 := "노란색"
T28 := "연갈색"
T29 := "빨간색"
T30 := "하얀색"
loop,
{
Guicontrol,, Statusline, (STEP401-3-1)
Gui, Submit, nohide
if Coin!=1
break
Freeze_Move()
Move_buy()
MapNumber := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
startinven := get_inven()
if(MapNumber=1203||MapNumber=4207||MapNumber=207||MapNumber=3203){
Guicontrol,, Statusline, (STEP401-3-2-1)
loop,2 {
if Coin!=1
break
if MapNumber = 1203
{
keyclick("CTRL1")
sleep, 1000
NPCMENUCLICK("Buy","CTRL1")
count := 19
}
else if MapNumber = 207
{
keyclick("CTRL2")
sleep, 1000
NPCMENUCLICK("Buy","CTRL2")
count := 30
}
else if MapNumber = 3203
{
keyclick("CTRL3")
sleep, 1000
NPCMENUCLICK("Buy","CTRL3")
count := 30
}
else if MapNumber = 4207
{
keyclick("CTRL4")
sleep, 1000
NPCMENUCLICK("Buy","CTRL4")
count := 30
}
sleep, 200
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
Now_Selected := 1
loop, %count% {
if Coin!=1
break
if (MapNumber = 1203)
target := "P"A_Index
else
target := "T"A_Index
target := %target%
target := AutoBuyPant%target%
if target = 1
loop,2{
keyclick("RightArrow")
}
keyclick("DownArrow")
Now_Selected++
}
sleep,10
loop,5 {
PostClick_OK()
sleep,200
}
sleep,1000
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
if Coin!=1
return
Temp:=Get_FP()
FPNow:=Temp.Now
FPMax:=Temp.Max
if FPNow <140
KeyClick(0)
inven := Get_inven()
Guicontrol,, Statusline, (STEP401-2-3-1) start %startinven% now start %inven%
if(inven>=49){
Freeze_Move()
sleep,1000
Search_Book(1)
sleep,3000
break
}
if (startinven < inven)
{
Num++
Search_Book(Num)
}
if Num=5
Num:=2
Sleep,3000
}
return
광물캐기:
Gui, Submit, Nohide
Global minimap_steps := 0 , PosX, PosY, MovePosX, MovePosY, stopmoving := 0, temp_x, temp_y
if(isFirstTimeRunThisCode := 1){
wall_remove_enable()
floor_remove_enable()
char_remove_enable()
start_inven := Get_inven()
isFirstTimeRunThisCode := 0
sleep, 100
Global mine_found := 0
Global Mines_Count := 0
for key, value in Mines
Mines_Count++
Global Mine_Error_Counter := A_TickCount
Guicontrol,, Statusline, (STEP19) 상태표시줄: [작동중] 광물캐기 설정완료 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving%
}
loop, {
Mine_found := 0
if(Coin!=1)
break
Global MapNumber := GetMapNumber()
Global original_MoveposX,original_MoveposY,remember_previous_posx,remember_previous_posy
MapBig := ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD0)+0xC)+0x10)+0x8)+0x264)
if(MapNumber=8){
loop,4{
Keyclick("UpArrow")
sleep,100
}
}
if(MapNumber=237&&MapBig!=1) {
postclick(725, 484)
sleep, 100
}
Guicontrol,, Statusline, (STEP20) 상태표시줄: [작동중] 광물캐기 시작 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving%
mining()
}
Guicontrol,, Statusline, (STEP21) 상태표시줄: [정지됨] 광물캐기 종료 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving%
wall_remove_disable()
floor_remove_disable()
char_remove_disable()
Return
자사먹자:
Gui, Submit, nohide
Guicontrol,, Statusline, 상태표시줄:  [자사먹자] 시작준비중
WindowTitle := Player1Title
if(isFirstTimeRunThisCode := 1){
wall_remove_enable()
floor_remove_enable()
char_remove_enable()
start_inven := Get_inven()
isFirstTimeRunThisCode := 0
sleep, 100
}
if(Coin!=1)
return
loop, {
Gui, Submit, nohide
if(Coin!=1)
break
MapNumber := GetMapNumber()
sleep,1
if(MapNumber=2241){
Click_CurrentMiniMapPos(-1,32)
sleep,1
postclick(clixkx,clicky)
sleep,1
}
ItemFound_Click(wanteditems,wanteditems_count)
sleep, 1
}
wall_remove_disable()
floor_remove_disable()
char_remove_disable()
return
Settingto800:
winmode:=800
return
Settingto1200:
winmode:=1200
return
Settingto1600:
winmode:=1600
return
SettingChanged:
Global Setting := ["Char_Setting","Tab1_Setting","Mines","wanteditems","AutoBuyItem","AutoBuyInk","AutoBuyPant","AutoBuyNeckla"]
Global Setting_Count := 0
for key, value in Setting
Setting_Count++
Loop, %Setting_Count% {
Setting_Key := A_Index
Setting_Value := Setting[Setting_Key]
Temp_Variable := Setting_Value
Temp_Count := 0
for key, value in %Temp_Variable%
Temp_Count++
Loop, %Temp_Count% {
Temp_Key := A_Index
Temp_Value := %Temp_Variable%[Temp_Key]
if(Setting_Value = "wanteditems"||Setting_Value = "Mines"||Setting_Value = "AutoBuyItem"||Setting_Value = "AutoBuyInk"||Setting_Value = "AutoBuyPant"||Setting_Value = "AutoBuyNeckla")
Temp_Variable_Child := %Temp_Variable%%Temp_Value%
else
Temp_Variable_Child := %Temp_Value%
GuiControlGet, Temp_Variable_Child
}
}
return
STEP188:
WindowTitle := Player1Title
SetFormat, integer, H
address := 0x00527ACC + 0x80
hexString := 107E5400430000001C7E54000000000000000000000101124700000000
WinGet, pid, pid, % OLDPROC := PROGRAM
if pid
{
hProcess := DllCall("OpenProcess", "Uint", 0x1F0FFF, "Int", 0, "Uint", pid)
if hProcess
{
size := StrLen(hexString) // Calculate the size of the string
buffer := DllCall("kernel32\VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "Ptr", size, "Uint", 0x3000, "Uint", 0x40)
DllCall("kernel32\RtlMoveMemory", "Ptr", buffer, "Str", hexString, "Ptr", size)
DllCall("WriteProcessMemory", "Ptr", hProcess, "Uint", address, "Ptr", buffer, "Uint", size, "Ptr", 0)
DllCall("kernel32\VirtualFreeEx", "Ptr", hProcess, "Ptr", buffer, "Ptr", 0, "Uint", 0x8000)
DllCall("CloseHandle", "Ptr", hProcess)
}
}
SetFormat, integer, d
return
멈가수련:
Gui, Submit, nohide
Guicontrol,, Statusline, (멈가수련)
windowtitle := player1title
Attck_Motion()
Freeze_Move()
char_remove_enable()
Move_Sell()
Move_Buy()
hit1 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
Mine_Error_Counter := A_TickCount
keyclick("AltR")
A:=1
B:=1
loop,
{
if(coin!=1)
break
delay := A_TickCount - Mine_Error_Counter
GuicontrolGet,robweapon_Select
if(robweapon_Select = 1)
{
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
if(current_weapon=0)
{
Guicontrol,, Statusline, (멈가수련) 장비를 착용합니다. 단축키%robweapon%
GuicontrolGet,robweapon
keyclick(robweapon)
loop,
{
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
if(current_weapon!=0)
break
else
{
keyclick(robweapon)
sleep,1000
B++
Guicontrol,, Statusline, (멈가수련) 장비 착용 실패. %B%
if(B>=2)
{
Guicontrol,, Statusline, (멈가수련) 장비 착용 실패. %B% 회 장비수리를 시도합니다.
GuicontrolGet, soya_x
GuicontrolGet, soya_y
GuicontrolGet, soya_c
GuicontrolGet, soya_n
postclick(730,530)
sleep, 10
postclick(soya_x,soya_y)
sleep,1
SoyaMENUCLICK("SELL",soya_x,soya_y)
loop, 2
{
if(Check_Shop("Sell")=0)
sleep, 1000
else
break
}
loop, 2 {
PostClick_First_Menu()
sleep, 250
}
loop,1 {
KeyClick("RightArrow")
sleep, 1
}
howmanyitems := soya_c - 1
loop,%howmanyitems% {
postmessage, 0x100, 40, 22020097, ,%WindowTitle%
postmessage, 0x101, 40, 22020097, ,%WindowTitle%
sleep, 1
loop,1 {
KeyClick("RightArrow")
sleep, 1
}
}
sleep,200
PostClick_OK()
sleep, 300
PostClick_Right_Menu()
sleep,100
sleep, 100
loop, 5
{
if(Check_Shop("Sell")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
sleep,100
postclick(soya_x,soya_y)
sleep,1
SoyaMENUCLICK("BUY",soya_x,soya_y)
loop, 5
{
if(Check_Shop("Buy")!=0)
break
else
sleep,1000
}
loop, 2 {
PostClick_First_Menu()
sleep, 250
}
soya_n:=soya_n-1
loop,%soya_n% {
postmessage, 0x100, 40, 22020097, ,%WindowTitle%
postmessage, 0x101, 40, 22020097, ,%WindowTitle%
sleep, 1
}
loop,%soya_c% {
KeyClick("RightArrow")
sleep, 1
}
sleep,200
PostClick_OK()
sleep, 300
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
keyclick(robweapon)
loop, 3
{
sleep,10
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
if(current_weapon=0){
keyclick(robweapon)
sleep,300
}
else
{
B:=0
break
}
}
}
}
}
delay := 6000
}
}
if (delay >= 6000) {
hit_x:= hit%A%
A++
hit%A%:= ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
hit_y := hit%A%
if(hit_x=hit_y)
{
Keyclick("Space")
sleep,100
Keyclick("Tab")
sleep,1000
Keyclick("Space")
sleep,100
Keyclick("Space")
}
if(A>5)
A:=1
Mine_Error_Counter := A_TickCount
}
guicontrol, ,detial_status, hit1: %hit1% hit2: %hit2% fhit3: %hit3% hit4: %hit4% hit5: %hit5%
if(rob_Select=1)
{
keyclick(rob)
sleep,1
postclick(rob_target_x,rob_target_y)
sleep,1
}
if(rob2_Select=1)
{
keyclick(rob2)
sleep,1
postclick(rob_target_x,rob_target_y)
sleep,1
}
if(rob3_Select=1)
{
keyclick(rob3)
sleep,1
postclick(rob_target_x,rob_target_y)
sleep,1
}
}
char_remove_disable()
keyclick("AltR")
return
무바:
Gui, Submit, nohide
Guicontrol,, Statusline, (무바)
windowtitle := player1title
Attck_Motion()
hit1 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
GuiControlGet,weapon_change
loop, 5
{
GuiControlGet,Weapon%A_Index%
}
GuiControlGet,noweapon
Guicontrol,, Statusline, (step189-0) %hit1%
A:=1
if(weapon_change="2무바")
A_limit :=3
else if(weapon_change="3무바")
A_limit :=4
else if(weapon_change="4무바")
A_limit :=5
else if(weapon_change="5무바")
A_limit :=6
loop,
{
if coin != 1
break
loop,
{
if coin != 1
break
hit2 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
sleep,1
if(hit2=hit1)
loop,
{
if coin != 1
break
hit2 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
sleep, 1
if(hit2!=hit1)
break
}
else if(hit1 != hit2)
{
Guicontrol,, Statusline, (step189-%A%) 무바 - %A%번무기 %hit1% %hit2%
break
}
}
if(noweapon = 1){
x := ReadMemory(ReadMemory(0x0058EB48)+0x44)-96
y := ReadMemory(ReadMemory(0x0058EB48)+0x48)-81
PostDoubleClick(x,y)
sleep, 1
}
else {
Weapon := Weapon%A%
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
sleep, 1
keyclick(Weapon)
sleep, 1
loop, 3
{
if coin != 1
break
changed_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
if(current_weapon=changed_weapon)
{
keyclick(Weapon)
sleep,1
}
else
break
}
sleep, 1
A++
if(A=A_limit)
A:=1
}
loop,
{
if coin != 1
break
hit1 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
sleep,1
if(hit2=hit1)
loop,
{
if coin != 1
break
hit1 := ReadMemory(ReadMemory(0x0058dad4)+0x1a5)
sleep, 1
if(hit2!=hit1)
break
}
else if(hit2!=hit1)
{
break
Guicontrol,, Statusline, (step189-%A%) 무바 - %A%번무기 끝 - 주먹 %hit1% %hit2%
}
}
Weapon := Weapon%A%
current_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
sleep, 1
keyclick(Weapon)
sleep, 1
loop, 3
{
if coin != 1
break
changed_weapon := ReadMemory(ReadMemory(0x0058DAD4)+0x121)
if(current_weapon=changed_weapon)
{
keyclick(Weapon)
sleep,1
}
else
break
}
sleep, 1
A++
if(A=A_limit)
A:=1
}
return
Check_Shop(what){
if(what="Buy")
{
Result := ReadMemory(0x0058EBB8)
return Result
}
else if(what="Repair")
{
Result := ReadMemory(0x0058F0C0)
return Result
}
else if(what="Sell")
{
Result := ReadMemory(0x0058F0C4)
return Result
}
return
}
NPCWriteMemory(hWnd, address, data){
VarSetCapacity(buffer, StrLen(data) + 1)
buffer := data
hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "UInt", hWnd)
DllCall("WriteProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", &buffer, "UInt", StrLen(data) + 1, "UInt", 0)
DllCall("CloseHandle", "Ptr", hProcess)
}
RUNNPC(address){
SetTitleMatchMode, 3
PROGRAM:= WindowTitle
WinGet, pid, pid, % OLDPROC := PROGRAM
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", address, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
autosellitem(){
NPCX := 421
NPCY := 195
KeyClick(Book)
sleep,500
Search_Book(1)
sleep,3000
sleep,10
loop,2 {
PostClick(NPCX,NPCY)
sleep,100
}
NPCMENUCLICK("SELL","N")
loop, 2 {
PostClick_First_Menu()
sleep, 250
}
howmanyitems := 40
each := 10
loop,%howmanyitems% {
postmessage, 0x100, 40, 22020097, ,%WindowTitle%
postmessage, 0x101, 40, 22020097, ,%WindowTitle%
sleep, 10
loop,%each% {
KeyClick("RightArrow")
sleep, 1
}
}
sleep,200
PostClick_OK()
sleep, 300
PostClick_Right_Menu()
sleep,100
loop, 5
{
if(Check_Shop("Sell")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
PostClick_OK(){
tempx := ReadMemory(ReadMemory(0x0058EB48) + 0x8C) + 423 - 233
tempy := ReadMemory(ReadMemory(0x0058EB48) + 0x90) + 322 - 173
PostClick(tempx,tempy)
}
PostClick_Right_Menu(){
tempx := ReadMemory(ReadMemory(0x0058EB48) + 0x8C) + 205 - 233
tempy := ReadMemory(ReadMemory(0x0058EB48) + 0x90) + 57 - 173
PostClick_Right(tempx,tempy)
}
PostClick_First_Menu(){
tempx := ReadMemory(ReadMemory(0x0058EB48) + 0x8C) + 205 - 233
tempy := ReadMemory(ReadMemory(0x0058EB48) + 0x90) + 57 - 173
PostClick(tempx,tempy)
}
Check_NPCMsg() {
NPCMsg := ReadMemoryTxt(0x0017E4EC)
Return NPCMsg
}
Check_NPCMsg1() {
NPCMsg := ReadMemoryTxt(0x0018E3E4)
Return NPCMsg
}
Check_FormNumber() {
FormNumber := ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD0)+0xC)+0x10)+0x8)+0xA0)
Return FormNumber
}
CharStatusCheck(){
Gui, Submit, nohide
Pos:=GetPos()
TempX := Pos.PosX
TempY := Pos.PosY
Guicontrol,, CharCurrentPos, 좌표 : X : %TempX%    Y: %TempY%
SetFormat, integer, d
Elancia_mapName := Get_Location()
MapNumber := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
guicontrolget,meditation_Select
guicontrolget,meditation
if meditation_Select = 1
keyclick(meditation)
guicontrolget,talk_Select
guicontrolget,talk
if talk_Select = 1
keyclick(talk)
Dimension := Readmemory(Readmemory(0x0058EB1C) + 0x10A)
if(Dimension>20000)
CharDimen:="감마"
else if(Dimension>10000)
CharDimen:="베타"
else if(Dimension<10000)
CharDimen:="알파"
SB_SetText(WindowTitle, 1)
SB_SetText(CharDimen "차원" Elancia_mapName " (" MapNumber ")", 2)
Guicontrol,, CharLocation, 위치 : (%Dimension%)%Elancia_mapName%(%MapNumber%)
Temp:=Get_HP()
HPNow:=Temp.Now
HPMax:=Temp.Max
HPPercent:=Temp.Percent
guicontrolget,critical_hppercent
guicontrolget,hpshortcut
Guicontrol,, CharCurrentHP, HP`: %HPNow% / %HPMax% `(%HPPercent%`%`)
if(HPPercent<=critical_hppercent && hpshortcut != "안함")
keyclick(hpshortcut)
Temp:=Get_MP()
MPNow:=Temp.Now
MPMax:=Temp.Max
MPPercent:=Temp.Percent
Guicontrol,, CharCurrentMP, MP`: %MPNow% / %MPMax% `(%MPPercent%`%`)
guicontrolget,critical_mppercent
guicontrolget,mpshortcut
if(MPPercent <= critical_mppercent && mpshortcut != "안함")
keyclick(mpshortcut)
Temp:=Get_FP()
FPNow:=Temp.Now
FPMax:=Temp.Max
FPPercent:=Temp.Percent
Guicontrol,, CharCurrentFP, FP`: %FPNow% / %FPMax% `(%FPPercent%`%`)
guicontrolget,critical_fppercent
guicontrolget,fpshortcut
if(FPPercent <= critical_fppercent && fpshortcut != "안함")
{
keyclick(fpshortcut)
Temp:=Get_FP()
increased := FPNow - Temp.Now
if increased <2
{
loop, 30
keyclick(fpshortcut)
}
}
Galid := Get_Galid()
Galid := FormatNumber(Galid)
Guicontrol,, CharCurrentGalid, 소지금`: %Galid%
Inven:= Get_inven()
Guicontrol,, CharCurrentItem, 아이템`: %inven% / 50
formNumber := Check_FormNumber()
Guicontrol,, Player%currentplayer%status,위치: %Elancia_mapName%(%MapNumber%) 인밴토리: %inven% / 50 %formNumber%
}
ItemFound_Click(wanteditems,wanteditems_count){
search_PosX := 2
search_PosY := 2
image_PosX := 1 + (search_PosX - 1) * 24
image_PosY := 1 + (search_PosY - 1) * 24
image_PosX_limit := 1 + (search_PosX + 25 - 1) * 24
image_PosY_limit := 1 + (search_PosX + 15 - 1) * 24
Loop, %wanteditems_count%
{
itemKey := A_Index
itemValue := wanteditems[itemKey]
tabname := "wanteditems"
checked := %tabname%%itemValue%
IfWinNotActive, %WindowTitle%
WinActivate,%WindowTitle%
if (checked = 1)
{
sleep,1
ImageSearch, target_PosX, target_PosY, image_PosX, image_PosY, image_PosX_limit, image_PosY_limit, *10 %itemValue%.png
sleep,1
if (ErrorLevel = 0)
{
Guicontrol,, Statusline, 상태표시줄: [작동중] 자사먹자, 아이템 %itemValue% 발견, 좌표 X: %target_PosX% | Y: %target_PosY%
targetX := Floor((target_PosX - 1) / 24) * 24 + 24 - 4 -11
targetY := Floor((target_PosY) / 24 + 1) * 24 - 23 + 11
postclick(targetX, targetY)
postmove(7, 755)
sleep,1
break
}
else if (ErrorLevel != 0)
{
A:=1
Loop, {
A++
IfExist %itemValue%%A%.png
{
ImageSearch, target_PosX, target_PosY, image_PosX, image_PosY, image_PosX_limit, image_PosY_limit, *10 %itemValue%%A%.png
sleep,1
if (ErrorLevel = 0)
{
Guicontrol,, Statusline, 상태표시줄: [작동중] 자사먹자, 아이템 %itemValue% 발견, 좌표 X: %target_PosX% | Y: %target_PosY%
targetX := Floor((target_PosX - 1) / 24) * 24 + 24 - 4 -11
targetY := Floor((target_PosY) / 24 + 1) * 24 - 23 + 11
postclick(targetX, targetY)
postmove(7, 755)
sleep,1
break
}
}
Else
break
}
Guicontrol,, Statusline, 상태표시줄: [작동중] 자사먹자, %itemValue% 스캔중
sleep, 100
}
}
}
}
mine_found_click_minimap(input_x,input_y){
MapNumber := GetMapNumber()
if(CheckMiniMap()!=1){
closemap()
movemap(MapNumber)
Mapreopen()
}
scale_factor_x := 2
scale_factor_y := 2
if(MapNumber=237){
translation_offset_x := 493
translation_offset_y := 479
}
else if(MapNumber=3300||MapNumber=3301){
translation_offset_x := 633
translation_offset_y := 476
}
else if(MapNumber=1403){
translation_offset_x := 594
translation_offset_y := 400
}
output_x := input_x * scale_factor_x + translation_offset_x
output_y := input_y * scale_factor_y + translation_offset_y
sleep,10
postclick(output_x, output_y)
}
try_search_mine(image_PosX, image_PosY, image_PosX_limit, image_PosY_limit){
Gui, Submit, Nohide
Loop, %Mines_Count% {
if(Coin!=1)
break
Key := A_Index
Value := Mines[Key]
IfExist %Value%.png
{
tabname := "Mines"
temp_do := %tabname%%Value%
if (temp_do = 1) {
IfWinNotActive, %WindowTitle%
WinActivate,%WindowTitle%
ImageSearch, target_PosX, target_PosY, image_PosX, image_PosY, image_PosX_limit, image_PosY_limit, *10 %Value%.png
if (ErrorLevel = 0) {
result := {"target_PosX":target_PosX, "target_PosY":target_PosY, "ErrorLevel":ErrorLevel}
return result
}
}
A:=1
Loop, {
A++
IfExist %Value%%A%.png
{
if (temp_do = 1) {
ImageSearch, target_PosX, target_PosY, image_PosX, image_PosY, image_PosX_limit, image_PosY_limit, *10 %Value%%A%.png
if (ErrorLevel = 0) {
result := {"target_PosX":target_PosX, "target_PosY":target_PosY, "ErrorLevel":ErrorLevel}
return result
}
}
}
Else
break
}
}
}
result := {"target_PosX":target_PosX, "target_PosY":target_PosY, "ErrorLevel":ErrorLevel}
return result
}
mining_do(){
if(Coin != 1)
return
A := 1
if(mine_found = 0)
return
loop, {
if(Coin != 1)
break
KeyClick(6)
KeyClick(6)
Pos:=GetPos()
PosX:=Pos.PosX
PosY:=Pos.PosY
sleep,1
MovePos:=Get_MovePos()
MovePosX:=MovePos.MovePosX
MovePosY:=MovePos.MovePosY
sleep,1
if(mine_found = 7) {
Guicontrol,, Statusline, (STEP16) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving%
loop, 2 {
Keyclick("Tab")
Keyclick("Space")
Keyclick("Tab")
sleep,100
}
mine_found := 0
break
}
else if(MoveposX = PosX && MoveposY = PosY) {
Guicontrol,, Statusline, (STEP15) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving%
loop, 2 {
Keyclick("Tab")
Keyclick("Space")
Keyclick("Tab")
sleep,100
}
mine_found := 0
break
}
else if(MoveposX != PosX || MoveposY != PosY) {
if(mine_found = 0) {
delay := A_TickCount - Mine_Error_Counter
if (delay >= 1000) {
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
Guicontrol,, Statusline, (STEP9) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_02)
if(remember_previous_posx = PosX && remember_previous_posx = PosY) {
stopmoving++
sleep,1
}
sleep,1
remember_previous_posx := PosX
remember_previous_posx := PosY
sleep,1
if(stopmoving >=2) {
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
original_MoveposX := MoveposX
original_MoveposY := MoveposY
Guicontrol,, Statusline, (STEP10) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_02_01)
MapNumber := GetMapNumber()
temp := Get_Map_minimap_click_coordi(MapNumber,minimap_steps)
postclick(temp.clickx, temp.clicky)
Sleep, 100
stopmoving := 0
mine_found := 0
Sleep, 100
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
if(original_MoveposX != MoveposX || original_MoveposY !=MoveposY) {
Guicontrol,, Statusline, (STEP11) 상태표시줄: [작동중] 광물캐기 | 비움직임 감지 - 탈출시도 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_02_02)
}
}
Mine_Error_Counter := A_TickCount
}
}
else if(mine_found = 1) {
delay := A_TickCount - Mine_Error_Counter
if (delay >= 1000) {
mine_found_click_minimap(temp_x,temp_y)
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
Guicontrol,, Statusline, (STEP12) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_03_01)
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
KeyClick("AltR")
if(remember_previous_posx = PosX && remember_previous_posy = PosY) {
stopmoving++
sleep,1
}
sleep,1
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
remember_previous_posx := PosX
remember_previous_posy := PosY
sleep,1
if(stopmoving >=5) {
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
original_MoveposX := MoveposX
original_MoveposY := MoveposY
sleep,1
Guicontrol,, Statusline, (STEP13) 상태표시줄: [작동중] 광물캐기 | 비움직임 감지 - 탈출시도 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_03_02)
MapNumber := GetMapNumber()
temp := Get_Map_minimap_click_coordi(MapNumber,minimap_steps)
Sleep, 100
postclick(temp.clickx, temp.clicky)
stopmoving := 0
mine_found := 0
Sleep, 100
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
if(original_MoveposX != MoveposX || original_MoveposY != MoveposY) {
Guicontrol,, Statusline, (STEP14) 상태표시줄: [작동중] 광물캐기 | 비움직임 감지 - 탈출시도 성공 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 다음미니맵: %minimap_steps% | 지연시간 %stopmoving% (STEP:Mining_do_03_03)
}
}
Mine_Error_Counter := A_TickCount
}
}
}
else
return
}
}
Check_Attack(){
Result := readmemory(readmemory(readmemory(0x0058DAD4)+0x178)+0xEB)
Return Result
}
Get_Map_minimap_click_coordi(MapNumber,minimap_steps){
Gui, Submit, Nohide
MapNumber := GetMapNumber()
if (minimap_steps = 0) {
if(MapNumber=237) {
clickx := 749
clicky := 563
elanx := 128
elany := 42
}
else if(MapNumber=3300) {
clickx := 728
clicky := 522
elanx := 48
elany := 23
}
else if(MapNumber=3301) {
clickx := 637
clicky := 521
elanx := 2
elany := 22
}
else{
clickx := 749
clicky := 563
elanx := 128
elany := 42
}
}
else if (minimap_steps = 1) {
if(MapNumber=237) {
clickx := 714
clicky := 560
elanx := 110
elany := 41
}
else if(MapNumber=3300) {
clickx := 750
clicky := 557
elanx := 59
elany := 40
}
else if(MapNumber=3301) {
clickx := 759
clicky := 502
elanx := 63
elany := 13
}
else{
clickx := 714
clicky := 560
elanx := 110
elany := 41
}
}
else if (minimap_steps = 2) {
if(MapNumber=237) {
clickx := 732
clicky := 507
elanx := 119
elany := 14
}
else if(MapNumber=3300) {
clickx := 663
clicky := 572
elanx := 15
elany := 48
}
else if(MapNumber=3301) {
clickx := 671
clicky := 572
elanx := 19
elany := 47
}
else{
clickx := 732
clicky := 507
elanx := 119
elany := 14
}
}
else if (minimap_steps = 3) {
if(MapNumber=237) {
clickx := 531
clicky := 507
elanx := 19
elany := 14
}
else if(MapNumber=3300) {
clickx := 654
clicky := 505
elanx := 11
elany := 14
}
else if(MapNumber=3301) {
clickx := 755
clicky := 571
elanx := 61
elany := 47
}
else{
clickx := 732
clicky := 507
elanx := 119
elany := 14
}
}
else if (minimap_steps = 4) {
if(MapNumber=237) {
clickx := 561
clicky := 571
elanx := 34
elany := 46
}
else{
clickx := 561
clicky := 571
elanx := 34
elany := 46
}
}
Result := { "clickx": clickx, "clicky": clicky, "elanx":elanx, "elany":elany }
return Result
}
GameIslandTextMacro(){
MapNumber := GetMapNumber()
if(MapNumber=3601)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 49, 131073, ,%WindowTitle%
postmessage, 0x101, 49, 131073, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3602)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 50, 196609, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3603)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 51, 262145, ,%WindowTitle%
postmessage, 0x101, 51, 262145, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3604)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 52, 327681, ,%WindowTitle%
postmessage, 0x101, 52, 327681, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3605)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 53, 393217, ,%WindowTitle%
postmessage, 0x101, 53, 393217, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3606)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 54, 458753, ,%WindowTitle%
postmessage, 0x101, 54, 458753, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3607)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 55, 524289, ,%WindowTitle%
postmessage, 0x101, 55, 524289, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3608)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 56, 589825, ,%WindowTitle%
postmessage, 0x101, 56, 589825, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3609)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 57, 655361, ,%WindowTitle%
postmessage, 0x101, 57, 655361, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
else if(MapNumber=3610)
{
loop, 1
{
postmessage, 0x100, 17, 1900545, ,%WindowTitle%
postmessage, 0x100, 48, 720897, ,%WindowTitle%
postmessage, 0x101, 48, 720897, ,%WindowTitle%
postmessage, 0x101, 17, 1900545, ,%WindowTitle%
sleep, 1
}
}
}
IME_CHECK(WinTitle){
WinGet,hWnd,ID,%WinTitle%
Return Send_ImeControl(ImmGetDefaultIMEWnd(hWnd),0x005,"")
}
Send_ImeControl(DefaultIMEWnd, wParam, lParam) {
DetectSave := A_DetectHiddenWindows
DetectHiddenWindows,ON
SendMessage 0x283, wParam,lParam,,ahk_id %DefaultIMEWnd%
if (DetectSave <> A_DetectHiddenWindows)
DetectHiddenWindows,%DetectSave%
return ErrorLevel
}
ImmGetDefaultIMEWnd(hWnd) {
return DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)
}
GameIslandMacroText(){
sleep,1000
WinActivate,%WindowTitle%
WinWaitActive,%WindowTitle%
send, !2
sleep,500
Send, !m
Sleep,500
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send,{vk15sc138}
Sleep,100
}
Sleep,500
send,wntkdnlthsu1{space}apsb{Tab}wntkdnlthsu2{space}apsb{Tab}wntkdnlthsu3{space}apsb{Tab}wntkdnlthsu4{space}apsb{Tab}wntkdnlthsu5{space}apsb{Tab}wntkdnlthsu6{space}apsb{Tab}wntkdnlthsu7{space}apsb{Tab}wntkdnlthsu8{space}apsb{Tab}wntkdnlthsu9{space}apsb{Tab}wntkdnlthsu10{space}apsb{enter}
}
GameIslandMouseClickEvent(){
MapNumber := GetMapNumber()
temp := get_CurrentMiniMapPos()
CurrentMiniMapPosX := temp.CurrentMiniMapPosX
CurrentMiniMapPosY := temp.CurrentMiniMapPosY
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
if (MapNumber == 3600)
{
if (PosX != 19 || PosY != 10)
{
KeyClick("AltR")
sleep, 1
TempX := CurrentMiniMapPosX - 12
TempY := CurrentMiniMapPosY - 29
PostClick(TempX,TempY)
}
else if (PosX = 19 && PosY = 10)
{
KeyClick("AltR")
sleep, 1
TempX := CurrentMiniMapPosX - 14
TempY := CurrentMiniMapPosY - 29
PostClick(TempX,TempY)
}
}
else if (MapNumber >= 3601 && MapNumber <= 3610)
{
if (PosX <= 31 && PosY <= 29)
{
sleep, 1
}
else if (PosY <= 27)
{
sleep, 1
}
else if (PosX = 33 && PosY = 28)
{
KeyClick("AltR")
sleep, 1
TempX := CurrentMiniMapPosX + 14
TempY := CurrentMiniMapPosY + 9
PostClick(TempX,TempY)
Guicontrol,, Statusline, 상태표시줄: [작동중] 게임섬 - 게임 시작 장소로 이동중(클릭1)
}
else if (PosX != 33 || PosY != 28)
{
KeyClick("AltR")
sleep, 1
TempX := CurrentMiniMapPosX + 16
TempY := CurrentMiniMapPosY + 6
PostClick(TempX,TempY)
Guicontrol,, Statusline, 상태표시줄: [작동중] 게임섬 - 게임 시작 장소로 이동중(클릭2)
}
}
}
mining(){
IfWinNotActive, %WindowTitle%
WinActivate,%WindowTitle%
if(Coin!=1)
return
MapNumber := GetMapNumber()
if(CheckMiniMap()=2)
MapSetting(MapNumber)
Sleep, 10
search_PosX := 17
search_PosY := 10
mine_found := 0
spiral_length := 1
direction := 0
steps := 0
Loop, 10{
KeyClick(6)
KeyClick(6)
Sleep, 10
if(Coin!=1)
break
Pixel_PosX := 1 + (17 - 1) * 24 + 12
Pixel_PosY := 1 + (10 - 1) * 24 + 12
IfWinNotActive, %WindowTitle%
WinActivate,%WindowTitle%
MapNumber := GetMapNumber()
KeyClick("AltR")
PixelGetColor, ColorID, Pixel_PosX, Pixel_PosY, RGB
Sleep, 1
if(ColorID != 0x000000 && ColorID != 0xDE8E94 && ColorID != 102473){
Guicontrol,, Statusline, (STEP1) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 캐릭터가 광물위에 있습니다 (STEP:Mining_01)
mine_found := 7
mining_do()
}
else{
Guicontrol,, Statusline, (STEP2) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 다음단계 진행중 (STEP:Mining_02_01)
Pos := GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
search_PosX := search_PosX - 4
search_PosY := search_PosY - 3
image_PosX := 1 + (search_PosX - 1) * 24
image_PosY := 1 + (search_PosY - 1) * 24
image_PosX_limit := 1 + (search_PosX + 7 - 1) * 24
image_PosY_limit := 1 + (search_PosX + 7 - 1) * 24
temp := try_search_mine(image_PosX, image_PosY, image_PosX_limit, image_PosY_limit)
target_PosX := temp.target_PosX
target_PosY := temp.target_PosY
if(Coin!=1)
break
if (temp.ErrorLevel = 0){
Guicontrol,, Statusline, (STEP3) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물을 찾았습니다. (근거리) (STEP:Mining_03_01)
targetX := Floor((target_PosX - 1) / 24) * 24 + 24 - 4
targetY := Floor((target_PosY) / 24 + 1) * 24 - 23
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
temp_x := Floor((target_PosX - 1) / 24) - 17 + PosX +1
temp_y := Floor((target_PosY - 1) / 24) - 9 + PosY
mine_found_click_minimap(temp_x,temp_y)
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
if(temp_x = MovePosX && temp_y = MovePosY){
mine_found := 1
mining_do()
}
}
else{
Guicontrol,, Statusline, (STEP4) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물을 찾고있습니다. (중거리) (STEP:Mining_02_01)
search_PosX := 9
search_PosY := 2
image_PosX := 1 + (search_PosX - 1) * 24
image_PosY := 1 + (search_PosY - 1) * 24
image_PosX_limit := 1 + (search_PosX + 16 - 1) * 24
image_PosY_limit := 1 + (search_PosY + 16 - 1) * 24
temp := try_search_mine(image_PosX, image_PosY, image_PosX_limit, image_PosY_limit)
target_PosX := temp.target_PosX
target_PosY := temp.target_PosY
if(Coin!=1)
break
if (temp.ErrorLevel = 0){
Guicontrol,, Statusline, (STEP5) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물을 찾았습니다. (중거리) (STEP:Mining_03_02)
targetX := Floor((target_PosX - 1) / 24) * 24 + 24 - 4
targetY := Floor((target_PosY) / 24 + 1) * 24 - 23
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
temp_x := Floor((target_PosX - 1) / 24) - 17 + PosX +1
temp_y := Floor((target_PosY - 1) / 24) - 9 + PosY
mine_found_click_minimap(temp_x,temp_y)
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
if(temp_x = MovePosX && temp_y = MovePosY){
mine_found := 1
mining_do()
}
}
else{
Guicontrol,, Statusline, (STEP6) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물을 찾고있습니다. (원거리) (STEP:Mining_02_01)
search_PosX := 3
search_PosY := 1
image_PosX := 1 + (search_PosX - 1) * 24
image_PosY := 1 + (search_PosY - 1) * 24
image_PosX_limit := 1 + (search_PosX + 28 - 1) * 24
image_PosY_limit := 1 + (search_PosY + 18 - 1) * 24
mine_found := 0
temp := try_search_mine(image_PosX, image_PosY, image_PosX_limit, image_PosY_limit)
target_PosX := temp.target_PosX
target_PosY := temp.target_PosY
if(Coin!=1)
break
if (temp.ErrorLevel = 0) {
Guicontrol,, Statusline, (STEP7) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물을 찾았습니다. (원거리) (STEP:Mining_03_03)
targetX := Floor((target_PosX - 1) / 24) * 24 + 24 - 4
targetY := Floor((target_PosY) / 24 + 1) * 24 - 23
Pos:= GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
temp_x := Floor((target_PosX - 1) / 24) - 17 + PosX +1
temp_y := Floor((target_PosY - 1) / 24) - 9 + PosY
mine_found_click_minimap(temp_x,temp_y)
sleep,1
MovePos := Get_MovePos()
MovePosX := MovePos.MovePosX
MovePosY := MovePos.MovePosY
sleep,1
if(temp_x = MovePosX && temp_y = MovePosY){
mine_found := 1
mining_do()
}
}
else{
MapNumber := GetMapNumber()
temp:=Get_Map_minimap_click_coordi(MapNumber,minimap_steps)
mine_found := 0
Sleep, 100
Random varx, 0, 4
Random vary, 0, 4
temp.clickx := temp.clickx + ((varx-2) * 2)
temp.clicky := temp.clicky + ((vary-2) * 2)
postclick(temp.clickx, temp.clicky)
mine_found := 0
Sleep, 100
Pos:=GetPos()
PosX := Pos.PosX
PosY := Pos.PosY
Sleep, 100
Guicontrol,, Statusline, (STEP8) 상태표시줄: [작동중] 광물캐기 | 현위치: %PosX% / %PosY% | 목적지 %MoveposX% / %MoveposY% | 찾은위치: %search_PosX% / %search_PosY% | 다음미니맵: %minimap_steps% | 광물찾기 실패, 다음미니맵으로 이동 (MapNumber:=%MapNumber%)
if(PosX < temp.elanx + 2 && PosX > temp.elanX - 2 && PosY < temp.elany + 2 && PosY > temp.elany - 2){
if(MapNumber=237 && minimap_steps = 4)
minimap_steps := 0
else if(MapNumber=3300 && minimap_steps = 3)
minimap_steps := 0
else if(MapNumber=3301 && minimap_steps = 3)
minimap_steps := 0
else
minimap_steps++
}
Sleep, 1
}
}
}
}
return
}
}
CheckMiniMap(){
MapNumber := GetMapNumber()
temp := get_CurrentMiniMapPos()
CurrentMiniMapPosX := temp.CurrentMiniMapPosX
CurrentMiniMapPosY := temp.CurrentMiniMapPosY
sleep,1
if(MapNumber = 237)
{
if(CurrentMiniMapPosX = 643 && CurrentMiniMapPosY = 538)
{
MiniMapStatus := 1
}
else if(CurrentMiniMapPosX != 54)
{
MiniMapStatus := 2
}
}
else if(MapNumber = 3300 || MapNumber = 3301)
{
if(CurrentMiniMapPosX = 712 && CurrentMiniMapPosY = 536)
{
MiniMapStatus := 1
}
else if(CurrentMiniMapPosX != 54)
{
MiniMapStatus := 2
}
}
else if(MapNumber = 1403)
{
if(CurrentMiniMapPosX = 693 && CurrentMiniMapPosY = 499)
{
MiniMapStatus := 1
}
else if(CurrentMiniMapPosX != 54)
{
MiniMapStatus := 2
}
}
else if(MapNumber != 237)
{
if(CurrentMiniMapPosX = 742 && CurrentMiniMapPosY = 542)
{
MiniMapStatus := 1
}
else if(CurrentMiniMapPosX != 54)
{
MiniMapStatus := 2
}
}
return MiniMapStatus
}
파티:
Gui, Submit, Nohide
loop,7
{
Player%A_Index%ID:=0
}
Global target
loop, 6
{
A:=A_index +1
Gui, Submit, Nohide
GuiControlGet, partyPlayer%A%Title
GuiControlGet, partyPlayer%A%Title_Selected
if(partyPlayer%A%Title_Selected = 1)
{
WindowTitle := partyPlayer%A%Title
if(WindowTitle!="") {
SetFormat, Integer, H
Player%A%ID := get_player_id()
WindowTitle := partyPlayer1Title
set_party_memory()
target := Player%A%ID
send_party_target(target)
run_590000()
sleep, 1
SetFormat, Integer, d
}
}
}
return
get_player_id() {
Start_Scan := 0
player_id := 0
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", PID, "UInt")
DllCall("ReadProcessMemory","UInt",ProcHwnd,"UInt",0x0058DAD4,"Str",Start_Scan,"UInt",4,"UInt *",0)
Loop 4
result += *(&Start_Scan + A_Index-1) << 8*(A_Index-1)
result := result+98
DllCall("ReadProcessMemory","UInt",ProcHwnd,"UInt",result,"Str",Start_Scan,"UInt",4,"UInt *",0)
Loop 4
player_id += *(&Start_Scan + A_Index-1) << 8*(A_Index-1)
DllCall("CloseHandle", "int", ProcHwnd)
Return, player_id
}
set_party_memory() {
SetFormat, Integer, H
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
target = FFF696BDE81F6AC6FFF417D0E85900200D8B011940CCE81A48890059C3FFF426
Addrs := 0x00590000
Loop, 5
{
A := SubStr(target, 1, 14)
C := Substr(target, 15)
target := C
write_sys_memory("0x"A, Addrs, PID)
Addrs := Addrs+7
}
}
Global currentNpcCall := 0
Global npcCallMutex := 0
run_npcid:
SetTimer, 원격NPC호출자동, 4400
return
stop_npcid:
SetTimer, 원격NPC호출자동, Off
return
원격NPC호출자동:
if(npcCallMutex = 1)
{
Guicontrol,, Statusline,  npcCallMutex is 1
return
}
Guicontrol,, Statusline,  원격NPC호출 진행중 %currentNpcCall%
_num := Readmemory(Readmemory(0x0058EB1C) + 0x10E)
_Dimension := Readmemory(Readmemory(0x0058EB1C) + 0x10A)
if(_Dimension>20000)
_CharDimen:="감마"
else if(_Dimension>10000)
_CharDimen:="베타"
else if(_Dimension<10000)
_CharDimen:="알파"
if(_num != 4005)
{
return
}
npcCallMutex := 1
IfInString, _CharDimen, 알파
{
if(currentNpcCall = 0 ){

    if(AAD = null){
        return
    }
call_npcid(AAD)
currentNpcCall := 1
npcCallMutex := 0
return
}else{
call_npcid(AAS)
currentNpcCall := 0
npcCallMutex := 0
return
}
npcCallMutex := 0
return
}
IfInString, _CharDimen, 베타
{
if(currentNpcCall = 0 ){
currentNpcCall := 1
call_npcid(BAD)
npcCallMutex := 0
return
}else{
currentNpcCall := 0
call_npcid(BAS)
npcCallMutex := 0
return
}
npcCallMutex := 0
return
}
IfInString, _CharDimen, 감마
{
if(currentNpcCall = 0 ){
currentNpcCall := 1
call_npcid(GAD)
npcCallMutex := 0
return
}else{
currentNpcCall := 0
call_npcid(GAS)
npcCallMutex := 0
return
}
npcCallMutex := 0
return
}
Return
call_npcid(nid){
SetFormat, Integer, H
EXECUTE_527ACC()
set_NPC_memory()
set_NPC_memory3(nid)
run_527B4C()
SetFormat, Integer, d
return
}
원격NPC호출:
WindowTitle:=Player1Title
IfWinExist, %WindowTitle%
{
SetFormat, Integer, H
EXECUTE_527ACC()
set_NPC_memory()
set_NPC_memory2()
run_527B4C()
SetFormat, Integer, d
}
else {  }
return
set_NPC_memory() {
SetFormat, Integer, H
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
target = 00004300547E10000000547E1C00000000000000000000010100000000000000
Addrs := 0x00527ACC
Loop, 5
{
A := SubStr(target, 1, 14)
C := Substr(target, 15)
target := C
write_sys_memory("0x"A, Addrs, PID)
Addrs := Addrs+7
}
}
set_NPC_memory2() {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
target = 40C700527ACCB88EE8000000001A000000C3FFFAAB0000000000000000000000
Addrs := 0x00527B4C
Loop, 5
{
A := SubStr(target, 1, 14)
C := Substr(target, 15)
target := C
write_sys_memory("0x"A, Addrs, PID)
Addrs := Addrs+7
}
guicontrolget,NPCID
WriteMemory(0x00527b54, NPCID, "UInt")
}
set_NPC_memory3(nid) {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
target = 40C700527ACCB88EE8000000001A000000C3FFFAAB0000000000000000000000
Addrs := 0x00527B4C
Loop, 5
{
A := SubStr(target, 1, 14)
C := Substr(target, 15)
target := C
write_sys_memory("0x"A, Addrs, PID)
Addrs := Addrs+7
}
WriteMemory(0x00527b54, nid, "UInt")
}
EXECUTE_527ACC() {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", pid, "UInt")
RegionSize := 200
PAGE_EXECUTE_READWRITE := 0x40
DllCall("VirtualProtectEx", "UInt", ProcHwnd, "UInt", 0x00527ACC, "UInt", RegionSize, "UInt", PAGE_EXECUTE_READWRITE, "UInt*", oldProtection)
DllCall("CloseHandle", "UInt", ProcHwnd)
}
run_527B4C() {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x00527B4C, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
send_party_target(target) {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
ChangeAddr := 0x00590020
DllCall("WriteProcessMemory", "UInt", ProcHwnd, "UInt", ChangeAddr, "UInt*", target, "UInt", 07, "Uint *", 0)
DllCall("CloseHandle", "int", ProcHwnd)
return
}
write_sys_memory(WVALUE,MADDRESS,PROGRAM) {
Process, wait, %PROGRAM%, 0.5
PID = %ErrorLevel%
if PID = 0
{
}
ProcessHandle := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", PID, "UInt")
DllCall("WriteProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Uint*", WVALUE, "Uint", 07, "Uint *", 0)
DllCall("CloseHandle", "int", ProcessHandle)
}
run_590000() {
WinGet, pid, PID, %WindowTitle%
ProcHwnd := DllCall("OpenProcess", "Int", 2035711, "Char", 0, "UInt", pid, "UInt")
DllCall("CreateRemoteThread", "Ptr", ProcHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0x00590000, "Ptr", 0, "UInt", 0, "Ptr", 0,"Ptr")
DllCall("CloseHandle", "int", ProcHwnd)
}
Mapreopen(){
if(UiTest(1) = 0 ) {
PostMessage, 0x100, 0xA4, 0,,%WindowTitle%
PostMessage, 0x100, 0x56, 3080193,,%WindowTitle%
PostMessage, 0x101, 0xA4, 0,,%WindowTitle%
MapBig := ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD0)+0xC)+0x10)+0x8)+0x264)
MapNumber:= GetMapNumber()
if(MapNumber=237&&MapBig!=1) {
sleep, 100
postclick(725, 484)
}
}
}
Search_Book(Num){
SetFormat,integer, H
BookX := ReadMemory(ReadMemory(0x0058EB48) + 0x0164)-99
BookY := ReadMemory(ReadMemory(0x0058EB48) + 0x0168)-117
SetFormat,integer, d
X1 := BookX+27
Y1 := BookY+45
Y2 := Y1+36
Y3 := Y2+36
Y4 := Y3+36
Y5 := Y4+36
MoveX := BookX+148
MoveY := BookY+207
if(Num = 0)
PostClick(MoveX,MoveY)
else if(Num = 1){
PostClick(X1,Y1)
sleep,100
PostClick(MoveX,MoveY)
}
else if(Num =2){
PostClick(X1,Y2)
sleep,100
PostClick(MoveX,MoveY)
}
else if(Num =3){
PostClick(X1,Y3)
sleep,100
PostClick(MoveX,MoveY)
}
else if(Num =4){
PostClick(X1,Y4)
sleep,100
PostClick(MoveX,MoveY)
}
else if(Num =5){
PostClick(X1,Y5)
sleep,100
PostClick(MoveX,MoveY)
}
}
PostMove(MouseX,MouseY){
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos% ,,%WindowTitle%
}
PostClick(MouseX,MouseY){
IF(winmode=800){
MouseX := MouseX
MouseY := MouseY
}
IF ELSE (winmode=1600){
MouseX := MouseX *2
MouseY := MouseY *2
}
IF ELSE (winmode=1200){
MouseX := MouseX *1.5
MouseY := MouseY *1.5
}
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos% ,,%WindowTitle%
PostMessage, 0x201, 1, %MousePos% ,,%WindowTitle%
PostMessage, 0x202, 0, %MousePos% ,,%WindowTitle%
}
PostDoubleClick(MouseX,MouseY){
IF(winmode=800){
MouseX := MouseX
MouseY := MouseY
}
IF ELSE (winmode=1600){
MouseX := MouseX *2
MouseY := MouseY *2
}
IF ELSE (winmode=1200){
MouseX := MouseX *1.5
MouseY := MouseY *1.5
}
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 1, %MousePos% ,,%WindowTitle%
PostMessage, 0x203, 1, %MousePos% ,,%WindowTitle%
PostMessage, 0x202, 0, %MousePos% ,,%WindowTitle%
}
PostClick_Right(MouseX,MouseY){
IF(winmode=800){
MouseX := MouseX
MouseY := MouseY
}
IF ELSE (winmode=1600){
MouseX := MouseX *2
MouseY := MouseY *2
}
IF ELSE (winmode=1200){
MouseX := MouseX *1.5
MouseY := MouseY *1.5
}
MousePos := MouseX | MouseY<< 16
PostMessage, 0x200, 0, %MousePos% ,,%WindowTitle%
PostMessage, 0x204, 1, %MousePos% ,,%WindowTitle%
PostMessage, 0x205, 0, %MousePos% ,,%WindowTitle%
}
SoyaMENUCLICK(what,npc_x,npc_y){
ErrorLevel_check := 0
loop, {
NPCMenu := ReadMemory(0x0058F0A4)
if Coin!=1
break
if(NPCMenu != 0)
{
break
}
else if(NPCMenu =0) {
ErrorLevel_check++
sleep, 500
if(ErrorLevel_check >5){
postclick(npc_x,npc_y)
ErrorLevel_check:=0
}
}
}
if (what = "Buy"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +10
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
else if (what = "Sell"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +31
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
else if (what = "Repair"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +55
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
loop,2 {
postclick(x,y)
sleep,100
}
}
NPCMENUCLICK(what,key){
ErrorLevel_check := 0
loop, {
NPCMenu := ReadMemory(0x0058F0A4)
if Coin!=1
break
if(NPCMenu != 0)
{
break
}
else if(NPCMenu =0) {
ErrorLevel_check++
sleep, 500
if(ErrorLevel_check >5){
keyclick(key)
ErrorLevel_check:=0
}
}
}
if (what = "Buy"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +10
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
else if (what = "Sell"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +31
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
else if (what = "Repair"){
X := ReadMemory(ReadMemory(0x0058F0A4)+0x9A) +55
Y := ReadMemory(ReadMemory(0x0058F0A4)+0x9E) +15
}
loop,2 {
postclick(x,y)
sleep,100
}
}
BuyBread(Bread_Sellers,start_inven){
gui, submit, nohide
Move_buy()
if Coin!=1
return
GuiControlGet, Cheese_Select
GuiControlGet, bread_Select
keyclick("CTRL1")
sleep, 1000
NPCMENUCLICK("Buy","CTRL1")
sleep, 200
loop, 5
{
if(Check_Shop("BUY")=0)
sleep, 1000
else
break
}
loop, 2 {
PostClick_First_Menu()
sleep, 200
}
if Bread_Sellers = 카딜라
{
FirstItem := 38
SecondItem := 40
}
else if Bread_Sellers = 샤네트
{
FirstItem := 25
SecondItem := 27
}
else if Bread_Sellers = 카레푸
{
FirstItem := 26
SecondItem := 28
}
else if Bread_Sellers = 쿠키
{
FirstItem := 26
SecondItem := 28
}
else if Bread_Sellers = 베스
{
FirstItem := 40
SecondItem := 42
}
else if Bread_Sellers = 오이피노
{
FirstItem := 40
SecondItem := 42
}
SecondItem := SecondItem - FirstItem
FirstItem := FirstItem - 1
loop,%FirstItem%{
keyclick("DownArrow")
}
if Cheese_Select = 1
{
sleep, 1
KeyClick(1)
sleep, 1
KeyClick(0)
sleep, 1
KeyClick(0)
sleep, 1
}
loop,%SecondItem% {
keyclick("DownArrow")
}
if bread_Select = 1
{
sleep, 1
KeyClick(1)
sleep, 1
KeyClick(0)
sleep, 1
KeyClick(0)
sleep, 1
}
PostClick_OK() // 구매 OK클릭
sleep, 100
ErrorCount := 0
Loop, {
if Coin!=1
break
inven := Get_inven()
if(inven>=48){
break
}
else{
PostClick_OK()
sleep,1
}
if(inven = Get_inven())
{
ErrorCount++
}
else
ErrprCount := 0
if(ErrorCount>1000)
break
}
sleep, 1000
loop, 2 {
PostClick_Right_Menu()
loop, 5
{
if(Check_Shop("Buy")=0)
break
else
{
PostClick_Right_Menu()
sleep,1000
}
}
}
}
CloseMap(){
PostMessage, 0x100, 0xA4, 0,,%WindowTitle%
PostMessage, 0x100, 0x56, 3080193,,%WindowTitle%
PostMessage, 0x101, 0xA4, 0,,%WindowTitle%
}
inputmenu(NPCNAME){
IfWinNotActive, %WindowTitle%
{
WinActivate,%WindowTitle%
sleep,30
}
Send, !m
Sleep,500
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send,{vk15sc138}
Sleep,100
}
send,%NPCNAME%{space}apsb{enter}
}
inputallsellers(NPCTYPE){
IfWinNotActive, %WindowTitle%
{
WinActivate,%WindowTitle%
sleep,30
}
Send, !m
Sleep,500
ime_status := % IME_CHECK("A")
if (ime_status = "0")
{
Send,{vk15sc138}
Sleep,100
}
if NPCTYPE = COOK
send, zkelffk{space}apsb{tab}tb{space}apsb{tab}zhvp{space}apsb{tab}tispxm{space}apsb{tab}qptm{space}apsb{tab}znzl{space}apsb{tab}zkfpvn{space}apsb{tab}dhdlvlsh{space}apsb{enter}
else if NPCTYPE = INK
send, tpslzh{space}apsb{tab}slzl{space}apsb{tab}zmfhfltm{space}apsb{enter}
else if NPCTYPE = PANT
send, vmffksh{space}apsb{tab}xpel{space}apsb{tab}alshtm{space}apsb{tab}vhql{space}apsb{enter}
sleep,3
}
Get_inven(){
inven := ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD4)+0x178)+0xBE)+0x14)
return inven
}
Get_jElancia_Titles(){
jElanciaArray := []
Winget, jElanciaArray, List, ahk_class Nexon.Elancia
jElancia_Count := 0
loop, %jElanciaArray%{
jElancia := jElanciaArray%A_Index%
WinGetTitle,WindowTitle%A_Index%,ahk_id %jElancia%
jElancia_Count++
}
Return jElancia_Count
}
Get_HP(){
Now := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x5B)
Max := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x1F)
Percent := floor((Now / Max) * 100)
HP := { "Now": Now, "Max": Max, "Percent":Percent }
return HP
}
Get_MP(){
Now := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x5F)
Max  := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x23)
Percent := floor((Now / Max) * 100)
MP := { "Now": Now, "Max": Max, "Percent":Percent }
return MP
}
Get_FP(){
Now := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x63)
Max := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x27)
Percent := floor((Now / Max) * 100)
FP := { "Now": Now, "Max": Max, "Percent":Percent }
return FP
}
Get_Galid(){
Galid := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x6F)
return Galid
}
Get_AGI(){
AGI := ReadMemory(ReadMemory(ReadMemory(0x0058DAd4) + 0x178) + 0x3F)
return AGI
}
Get_Location(){
mem := get_mem()
DllName := "jelancia_core.dll"
moduleBase := mem.getModuleBaseAddress(DllName)
Location := ReadMemoryTxt(ReadMemory(moduleBase + 0x44A28)+ 0xC)
return Location
}
Get_Location2()
{
mem := get_mem()
DllName := "jelancia_core.dll"
moduleBase := mem.getModuleBaseAddress(DllName)
Location := ReadMemoryTxt(ReadMemory(moduleBase + 0x44A28))
return Location
}
Get_Location3()
{
mem := get_mem()
SetFormat, integer, H
jelanCoreAdd := mem.getModuleBaseAddress("jelancia_core.dll")
LocationPointerAdd := jelanCoreAdd + 0x00076508
SetFormat, integer, D
Location := mem.readString(LocationPointerAdd, 50, "UTF-16",0)
}
GetPos(){
PosX := ReadMemory(ReadMemory(0x0058DAd4) + 0x10)
PosY := ReadMemory(ReadMemory(0x0058DAd4) + 0x14)
result := { "PosX": PosX, "PosY": PosY}
return result
}
get_NPCTalk_cordi(){
x := ReadMemory(ReadMemory(0x0058EB48)+0xC8)
y := ReadMemory(ReadMemory(0x0058EB48)+0xCC)
Result := {"x":x, "y":y}
Return Result
}
Get_MovePos(){
MovePosX := ReadMemory(0x0058EA10)
MovePosY := ReadMemory(0x0058EA14)
Result := {"MovePosX":MovePosX, "MovePosY":MovePosY}
Return Result
}
GetMapNumber(){
if(ReadMemory(0x0058EB6C) = 0) {
PostMessage, 0x100, 0xA4, 0,,%WindowTitle%
PostMessage, 0x100, 0x56, 3080193,,%WindowTitle%
PostMessage, 0x101, 0xA4, 0,,%WindowTitle%
}
MapSize := ReadMemory(ReadMemory(ReadMemory(ReadMemory(ReadMemory(0x0058DAD0)+0xC)+0x10)+0x8)+0x264)
if(MapSize != 1)
MapSize := 0
else If(MapSize = 1)
MapSize := 1
MapNumber := ReadMemory(ReadMemory(0x0058EB6C) + 0x0188)
SetFormat,integer, d
return MapNumber
}
get_CurrentMiniMapPos(){
CurrentMiniMapPosX := ReadMemory(ReadMemory(0x0058EB48) +0x80)
CurrentMiniMapPosY := ReadMemory(ReadMemory(0x0058EB48) +0x84)
result := {"CurrentMiniMapPosX":CurrentMiniMapPosX,"CurrentMiniMapPosY":CurrentMiniMapPosY}
return result
}
get_lastclicknpc(){
npcid:=ReadMemory(0x00584C2C)
return npcid
}
MapSetting(MapNumber){
if(UiTest(1) != 0 )
{
CloseMap()
sleep, 10
}
MoveMap(MapNumber)
sleep, 10
Mapreopen()
}
MoveMap(MapNumber){
if(MapNumber=237)
{
WriteMemory(ReadMemory(0x0058EB48) + 0x80, 0x83, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x81, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x82, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x83, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x84, 0x1A, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x85, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x86, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x87, 0x00, "char")
}
else if(MapNumber=3300 || MapNumber=3301)
{
WriteMemory(ReadMemory(0x0058EB48) + 0x80, 0xC8, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x81, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x82, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x83, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x84, 0x18, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x85, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x86, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x87, 0x00, "char")
}
else if(MapNumber=1403)
{
WriteMemory(ReadMemory(0x0058EB48) + 0x80, 0xB5, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x81, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x82, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x83, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x84, 0xF3, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x85, 0x01, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x86, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x87, 0x00, "char")
}
else if(MapNumber>=3601&&MapNumber<=3610)
{
WriteMemory(ReadMemory(0x0058EB48) + 0x80, 0xE6, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x81, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x82, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x83, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x84, 0x1E, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x85, 0x02, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x86, 0x00, "char")
WriteMemory(ReadMemory(0x0058EB48) + 0x87, 0x00, "char")
}
else{
return
}
return
}
UiTest(TestNum){
if(TestNum = 1) {
UIMap := ReadMemory(0x0058EB6C)
sleep, 1
return UIMap
}
else if(TestNum = 2) {
UIRas := ReadMemory(0x0058F0CC)
return UIRas
}
}
Click_CurrentMiniMapPos(A,B){
CurrentMiniMapPosX := ReadMemory(ReadMemory(0x0058EB48) +0x80)+A
CurrentMiniMapPosY := ReadMemory(ReadMemory(0x0058EB48) +0x84)+B
postclick(CurrentMiniMapPosX,CurrentMiniMapPosY)
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
ride_enable(){
WriteMemory(0x0046035B, 0x90, "char")
WriteMemory(0x0046035C, 0x90, "char")
WriteMemory(0x0046035D, 0x90, "char")
WriteMemory(0x0046035E, 0x90, "char")
WriteMemory(0x0046035F, 0x90, "char")
WriteMemory(0x00460360, 0x90, "char")
}
ride_disable(){
WriteMemory(0x0046035B, 0x89, "char")
WriteMemory(0x0046035C, 0x83, "char")
WriteMemory(0x0046035D, 0x6B, "char")
WriteMemory(0x0046035E, 0x01, "char")
WriteMemory(0x0046035F, 0x00, "char")
WriteMemory(0x00460360, 0x00, "char")
}
wall_remove_enable(){
WriteMemory(0x0047AA5B,  0xEB, "char")
}
wall_remove_disable(){
WriteMemory(0x0047AA5B,  0x7d, "char")
}
floor_remove_enable(){
WriteMemory(0x0047A196,  0xEB, "char")
}
floor_remove_disable(){
WriteMemory(0x0047A196,  0x75, "char")
}
char_remove_enable(){
WriteMemory(0x0045D28F,  0xE9, "char")
WriteMemory(0x0045D290,  0x8A, "char")
WriteMemory(0x0045D291,  0x0A, "char")
WriteMemory(0x0045D292,  0x00, "char")
WriteMemory(0x0045D293,  0x00, "char")
}
char_remove_disable(){
WriteMemory(0x0045D28F,  0x0F, "char")
WriteMemory(0x0045D290,  0x84, "char")
WriteMemory(0x0045D291,  0xC2, "char")
WriteMemory(0x0045D292,  0x00, "char")
WriteMemory(0x0045D293,  0x00, "char")
}
Freeze_Move(){
WriteMemory(0x0047AD78,  0x90, "char")
WriteMemory(0x0047AD79,  0x90, "char")
WriteMemory(0x0047AD7A,  0x90, "char")
}
Un_Freeze_Move(){
WriteMemory(0x0047AD78, 0x8B, "char")
WriteMemory(0x0047AD79,  0x4E, "char")
WriteMemory(0x0047AD7A,  0x04, "char")
}
Buy_Unlimitted(){
WriteMemory(0x0042483A, 0xB0, "char")
WriteMemory(0x0042483B, 0x01, "char")
WriteMemory(0x0042483C, 0x90, "char")
WriteMemory(0x0042483D, 0x90, "char")
WriteMemory(0x0042483E, 0x90, "char")
WriteMemory(0x0042483F, 0x90, "char")
}
Attck_Motion(){
WriteMemory(0x0047C1A9, 0x6a, "char")
WriteMemory(0x0047C1AA, 0x00, "char")
WriteMemory(0x0047C1AB, 0x90, "char")
WriteMemory(0x0047C1AC, 0x90, "char")
WriteMemory(0x0047C1AD, 0x90, "char")
}
Move_Buy(){
WriteMemory(ReadMemory(0x0058EB48) + 0x8C, 233, "UInt")
WriteMemory(ReadMemory(0x0058EB48) + 0x90, 173, "UInt")
}
Move_Sell(){
WriteMemory(ReadMemory(0x0058EB48) + 0x98, 233, "UInt")
WriteMemory(ReadMemory(0x0058EB48) + 0x9C, 173, "UInt")
}
Move_Repair(){
WriteMemory(ReadMemory(0x0058EB48) + 0xA4,  230, "UInt")
WriteMemory(ReadMemory(0x0058EB48) + 0xA8,  170, "UInt")
}
FormatNumber(Amount) {
StringReplace Amount, Amount, -
IfEqual ErrorLevel,0, SetEnv Sign,-
Loop Parse, Amount, .
If (A_Index = 1) {
len := StrLen(A_LoopField)
Loop Parse, A_LoopField
If (Mod(len-A_Index,3) = 0 and A_Index != len)
x = %x%%A_LoopField%,
Else x = %x%%A_LoopField%
}
Else Return Sign x "." A_LoopField
Return Sign x
}
RefleshWindowList(TitleNumber){
jElancia_Count := Get_jElancia_Titles()
GuiControl,, Player%TitleNumber%title,|
Loop, %jElancia_Count%{
temp_Variable := WindowTitle%A_Index%
GuiControl,, Player%TitleNumber%title, %temp_Variable%
}
GuiControl, Choose, Player%TitleNumber%title, %TitleNumber%
}
RefleshPartyWindowList(TitleNumber){
jElancia_Count := Get_jElancia_Titles()
GuiControl,, partyPlayer%TitleNumber%title,|
Loop, %jElancia_Count%{
temp_Variable := WindowTitle%A_Index%
GuiControl,, partyPlayer%TitleNumber%title, %temp_Variable%
}
GuiControl, Choose, partyPlayer%TitleNumber%title, %TitleNumber%
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
ReadMemoryTxt(MADDRESS) {
WinGet, pid, PID, %WindowTitle%
VarSetCapacity(MVALUE, 131, 0)
ProcessHandle := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", pid, "UInt")
DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Str", MVALUE, "UInt", 131, "UInt *", 0)
return MVALUE
}
WriteMemory(WriteAddress = "", Data="", TypeOrLength = ""){
PROGRAM:=WindowTitle
Static OLDPROC, hProcess, pid
If (PROGRAM != OLDPROC){
if hProcess
closed := DllCall("CloseHandle", "UInt", hProcess), hProcess := 0, OLDPROC := ""
if PROGRAM{
WinGet, pid, pid, % OLDPROC := PROGRAM
jPID = pid
if !pid
return "Process Doesn't Exist", OLDPROC := ""
hProcess := DllCall("OpenProcess", "Int", 0x8 | 0x20, "Int", 0, "UInt", pid)
}
}
If Data is Number
{
If TypeOrLength is Integer
{
DataAddress := Data
DataSize := TypeOrLength
}
Else{
If (TypeOrLength = "Double" or TypeOrLength = "Int64")
DataSize = 8
Else If (TypeOrLength = "Int" or TypeOrLength = "UInt" or TypeOrLength = "Float")
DataSize = 4
Else If (TypeOrLength = "Short" or TypeOrLength = "UShort")
DataSize = 2
Else If (TypeOrLength = "Char" or TypeOrLength = "UChar")
DataSize = 1
Else {
Return False
}
VarSetCapacity(Buf, DataSize, 0)
NumPut(Data, Buf, 0, TypeOrLength)
DataAddress := &Buf
}
}
Else{
DataAddress := &Data
If TypeOrLength is Integer
{
If A_IsUnicode
DataSize := TypeOrLength * 2
Else
DataSize := TypeOrLength
}
Else{
If A_IsUnicode
DataSize := (StrLen(Data) + 1) * 2
Else
DataSize := StrLen(Data) + 1
}
}
if (hProcess && DllCall("WriteProcessMemory", "UInt", hProcess
, "UInt", WriteAddress
, "UInt", DataAddress
, "UInt", DataSize
, "UInt", 0))
return
else return !hProcess ? "Handle Closed:" closed : "Fail"
}
SetStaticColor(hStatic, b_color, f_color := 0){
static arr := [], GWL_WNDPROC := -4
b_color := DllCall("Ws2_32\ntohl", UInt, b_color << 8, UInt)
f_color := DllCall("Ws2_32\ntohl", UInt, f_color << 8, UInt)
hGui := DllCall("GetParent", Ptr, hStatic, Ptr)
if !arr.HasKey(hGui)  {
arr[hGui] := {}, arr[hGui].Statics := []
arr[hGui].ProcOld := DllCall("SetWindowLong" . (A_PtrSize = 8 ? "Ptr" : ""), Ptr, hGui, Int, GWL_WNDPROC
, Ptr, RegisterCallback("WindowProc", "", 4, Object(arr[hGui])), Ptr)
}
else if arr[hGui].Statics.HasKey(hStatic)
DllCall("DeleteObject", Ptr, arr[hGui].Statics[hStatic].hBrush)
arr[hGui].Statics[hStatic] := { b_color: b_color, f_color: f_color
, hBrush: DllCall("CreateSolidBrush", UInt, b_color, Ptr) }
WinSet, Redraw,, ahk_id %hStatic%
}
WindowProc(hwnd, uMsg, wParam, lParam) {
Critical
static WM_CTLCOLORSTATIC := 0x138
obj := Object(A_EventInfo)
if (uMsg = WM_CTLCOLORSTATIC && k := obj.Statics[lParam])  {
DllCall("SetBkColor", Ptr, wParam, UInt, k.b_color)
DllCall("SetTextColor", Ptr, wParam, UInt, k.f_color)
Return k.hBrush
}
Return DllCall("CallWindowProc", Ptr, obj.ProcOld, Ptr, hwnd, UInt, uMsg, Ptr, wParam, Ptr, lParam)
}
getModuleBaseAddress(module := ""){
WinGet, pid, pid, %WindowTitle%
if pid
hProc := DllCall("OpenProcess", "UInt", 0x0400 | 0x0010 , "Int", 0, "UInt", pid)
else return -2
if !hProc
return -3
if (A_PtrSize = 4)
{
DllCall("IsWow64Process", "Ptr", hProc, "Int*", result)
if !result
return -5, DllCall("CloseHandle","Ptr",hProc)
}
if (module = "")
{
VarSetCapacity(mainExeNameBuffer, 2048 * (A_IsUnicode ? 2 : 1))
DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "UInt", 0
, "Ptr", &mainExeNameBuffer, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
mainExeFullPath := StrGet(&mainExeNameBuffer)
}
size := VarSetCapacity(lphModule, 4)
loop
{
DllCall("psapi\EnumProcessModules", "Ptr", hProc, "Ptr", &lphModule
, "UInt", size, "UInt*", reqSize)
if ErrorLevel
return -4, DllCall("CloseHandle","Ptr",hProc)
else if (size >= reqSize)
break
else
size := VarSetCapacity(lphModule, reqSize)
}
VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
loop % reqSize / A_PtrSize
{
DllCall("psapi\GetModuleFileNameEx", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
, "Ptr", &lpFilename, "UInt", 2048 / (A_IsUnicode ? 2 : 1))
moduleFullPath := StrGet(&lpFilename)
SplitPath, moduleFullPath, fileName
if (module = "" && mainExeFullPath = moduleFullPath) || (module != "" && module = filename)
{
VarSetCapacity(MODULEINFO, A_PtrSize = 4 ? 12 : 24)
DllCall("psapi\GetModuleInformation", "Ptr", hProc, "Ptr", numget(lphModule, (A_index - 1) * A_PtrSize)
, "Ptr", &MODULEINFO, "UInt", A_PtrSize = 4 ? 12 : 24)
return numget(MODULEINFO, 0, "Ptr"), DllCall("CloseHandle","Ptr",hProc)
}
}
return -1, DllCall("CloseHandle","Ptr",hProc)
}
get_mem(){
if (_ClassMemory.__Class != "_ClassMemory")
{
gosub,Stop_this
}
mem := new _ClassMemory(WindowTitle,, hProcessCopy)
if !isObject(mem)
{
if (hProcessCopy = 0){
}
else if (hProcessCopy = ""){
}
gosub,Stop_this
}return mem
}
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
return this
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
version()
{
return 2.92
}
findPID(program, windowMatchMode := "3")
{
if RegExMatch(program, "i)\s*AHK_PID\s+(0x[[:xdigit:]]+|\d+)", pid)
return pid1
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
SplitPath, fileName , fileName
if (fileName)
{
process, Exist, %fileName%
pid := ErrorLevel
}
}
return pid ? pid : 0
}
isHandleValid()
{
return 0x102 = DllCall("WaitForSingleObject", "Ptr", this.hProcess, "UInt", 0)
}
openProcess(PID, dwDesiredAccess)
{
r := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr")
if (!r && A_LastError = 5)
{
this.setSeDebugPrivilege(true)
if (r2 := DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr"))
return r2
DllCall("SetLastError", "UInt", 5)
}
return r ? r : ""
}
closeHandle(hProcess)
{
return DllCall("CloseHandle", "Ptr", hProcess)
}
numberOfBytesRead()
{
return !this.pNumberOfBytesRead ? -1 : NumGet(this.pNumberOfBytesRead+0, "Ptr")
}
numberOfBytesWritten()
{
return !this.pNumberOfBytesWritten ? -1 : NumGet(this.pNumberOfBytesWritten+0, "Ptr")
}
read(address, type := "UInt", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
return "", ErrorLevel := -2
if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", result, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesRead)
return result
return
}
readRaw(address, byRef buffer, bytes := 4, aOffsets*)
{
VarSetCapacity(buffer, bytes)
return DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", bytes, "Ptr", this.pNumberOfBytesRead)
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
return "", this.ReadStringLastError := True
else loop, %loopCount%
{
if NumGet(buffer, (A_Index - 1) * encodingSize, charType) = 0
{
if (bufferSize < sizeBytes := outterIndex * 4 - (4 - A_Index * encodingSize))
VarSetCapacity(buffer, sizeBytes)
break, 2
}
}
}
}
if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesRead)
return StrGet(&buffer,, encoding)
return "", this.ReadStringLastError := True
}
writeString(address, string, encoding := "utf-8", aOffsets*)
{
encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
requiredSize := StrPut(string, encoding) * encodingSize - (this.insertNullTerminator ? 0 : encodingSize)
VarSetCapacity(buffer, requiredSize)
StrPut(string, &buffer, StrLen(string) + (this.insertNullTerminator ?  1 : 0), encoding)
return DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", &buffer, "Ptr", requiredSize, "Ptr", this.pNumberOfBytesWritten)
}
write(address, value, type := "Uint", aOffsets*)
{
if !this.aTypeSize.hasKey(type)
return "", ErrorLevel := -2
return DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", value, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesWritten)
}
writeRaw(address, pBuffer, sizeBytes, aOffsets*)
{
return DllCall("WriteProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, "Ptr", pBuffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesWritten)
}
writeBytes(address, hexStringOrByteArray, aOffsets*)
{
if !IsObject(hexStringOrByteArray)
{
if !IsObject(hexStringOrByteArray := this.hexStringToPattern(hexStringOrByteArray))
return hexStringOrByteArray
}
sizeBytes := this.getNeedleFromAOBPattern("", buffer, hexStringOrByteArray*)
return this.writeRaw(address, &buffer, sizeBytes, aOffsets*)
}
pointer(address, finalType := "UInt", offsets*)
{
For index, offset in offsets
address := this.Read(address, this.ptrType) + offset
Return this.Read(address, finalType)
}
getAddressFromOffsets(address, aOffsets*)
{
return  aOffsets.Remove() + this.pointer(address, this.ptrType, aOffsets*)
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
return DllCall(A_PtrSize = 4
? "GetWindowLong"
: "GetWindowLongPtr"
, "Ptr", hWnd, "Int", -6, A_Is64bitOS ? "Int64" : "UInt")
}
getModuleBaseAddress(moduleName := "", byRef aModuleInfo := "")
{
aModuleInfo := ""
if (moduleName = "")
moduleName := this.GetModuleFileNameEx(0, True)
if r := this.getModules(aModules, True) < 0
return r
return aModules.HasKey(moduleName) ? (aModules[moduleName].lpBaseOfDll, aModuleInfo := aModules[moduleName]) : -1
}
getModuleFromAddress(address, byRef aModuleInfo, byRef offsetFromModuleBase := "")
{
aModuleInfo := offsetFromModule := ""
if result := this.getmodules(aModules) < 0
return result
for k, module in aModules
{
if (address >= module.lpBaseOfDll && address < module.lpBaseOfDll + module.SizeOfImage)
return 1, aModuleInfo := module, offsetFromModuleBase := address - module.lpBaseOfDll
}
return -1
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
return r
}
isTargetProcess64Bit(PID, hProcess := "", currentHandleAccess := "")
{
if !A_Is64bitOS
return False
else if !hProcess || !(currentHandleAccess & (this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_QUERY_LIMITED_INFORMATION))
closeHandle := hProcess := this.openProcess(PID, this.aRights.PROCESS_QUERY_INFORMATION)
if (hProcess && DllCall("IsWow64Process", "Ptr", hProcess, "Int*", Wow64Process))
result := !Wow64Process
return result, closeHandle ? this.CloseHandle(hProcess) : ""
}
suspend()
{
return DllCall("ntdll\NtSuspendProcess", "Ptr", this.hProcess)
}
resume()
{
return DllCall("ntdll\NtResumeProcess", "Ptr", this.hProcess)
}
getModules(byRef aModules, useFileNameAsKey := False)
{
if (A_PtrSize = 4 && this.IsTarget64bit)
return -4
aModules := []
if !moduleCount := this.EnumProcessModulesEx(lphModule)
return -3
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
return moduleCount
}
getEndAddressOfLastModule(byRef aModuleInfo := "")
{
if !moduleCount := this.EnumProcessModulesEx(lphModule)
return -3
hModule := numget(lphModule, (moduleCount - 1) * A_PtrSize)
if this.GetModuleInformation(hModule, aModuleInfo)
return aModuleInfo.lpBaseOfDll + aModuleInfo.SizeOfImage
return -5
}
GetModuleFileNameEx(hModule := 0, fileNameNoPath := False)
{
VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1))
DllCall("psapi\GetModuleFileNameEx"
, "Ptr", this.hProcess
, "Ptr", hModule
, "Str", lpFilename
, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
if fileNameNoPath
SplitPath, lpFilename, lpFilename
return lpFilename
}
EnumProcessModulesEx(byRef lphModule, dwFilterFlag := 0x03)
{
lastError := A_LastError
size := VarSetCapacity(lphModule, 4)
loop
{
DllCall("psapi\EnumProcessModulesEx"
, "Ptr", this.hProcess
, "Ptr", &lphModule
, "Uint", size
, "Uint*", reqSize
, "Uint", dwFilterFlag)
if ErrorLevel
return 0
else if (size >= reqSize)
break
else size := VarSetCapacity(lphModule, reqSize)
}
DllCall("SetLastError", "UInt", lastError)
return reqSize // A_PtrSize
}
GetModuleInformation(hModule, byRef aModuleInfo)
{
VarSetCapacity(MODULEINFO, A_PtrSize * 3), aModuleInfo := []
return DllCall("psapi\GetModuleInformation"
, "Ptr", this.hProcess
, "Ptr", hModule
, "Ptr", &MODULEINFO
, "UInt", A_PtrSize * 3)
, aModuleInfo := {  lpBaseOfDll: numget(MODULEINFO, 0, "Ptr")
,   SizeOfImage: numget(MODULEINFO, A_PtrSize, "UInt")
,   EntryPoint: numget(MODULEINFO, A_PtrSize * 2, "Ptr") }
}
hexStringToPattern(hexString)
{
AOBPattern := []
hexString := RegExReplace(hexString, "(\s|0x)")
StringReplace, hexString, hexString, ?, ?, UseErrorLevel
wildCardCount := ErrorLevel
if !length := StrLen(hexString)
return -1
else if RegExMatch(hexString, "[^0-9a-fA-F?]")
return -2
else if Mod(wildCardCount, 2)
return -3
else if Mod(length, 2)
return -4
loop, % length/2
{
value := "0x" SubStr(hexString, 1 + 2 * (A_index-1), 2)
AOBPattern.Insert(value + 0 = "" ? "?" : value)
}
return AOBPattern
}
stringToPattern(string, encoding := "UTF-8", insertNullTerminator := False)
{
if !length := StrLen(string)
return -1
AOBPattern := []
encodingSize := (encoding = "utf-16" || encoding = "cp1200") ? 2 : 1
requiredSize := StrPut(string, encoding) * encodingSize - (insertNullTerminator ? 0 : encodingSize)
VarSetCapacity(buffer, requiredSize)
StrPut(string, &buffer, length + (insertNullTerminator ?  1 : 0), encoding)
loop, % requiredSize
AOBPattern.Insert(NumGet(buffer, A_Index-1, "UChar"))
return AOBPattern
}
modulePatternScan(module := "", aAOBPattern*)
{
MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000
, PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100
if (result := this.getModuleBaseAddress(module, aModuleInfo)) <= 0
return "", ErrorLevel := result
if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
return -10
if (result := this.PatternScan(aModuleInfo.lpBaseOfDll, aModuleInfo.SizeOfImage, patternMask, AOBBuffer)) >= 0
return result
address := aModuleInfo.lpBaseOfDll
endAddress := address + aModuleInfo.SizeOfImage
loop
{
if !this.VirtualQueryEx(address, aRegion)
return -9
if (aRegion.State = MEM_COMMIT
&& !(aRegion.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aRegion.RegionSize >= patternSize
&& (result := this.PatternScan(address, aRegion.RegionSize, patternMask, AOBBuffer)) > 0)
return result
} until (address += aRegion.RegionSize) >= endAddress
return 0
}
addressPatternScan(startAddress, sizeOfRegionBytes, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
return -10
return this.PatternScan(startAddress, sizeOfRegionBytes, patternMask, AOBBuffer)
}
processPatternScan(startAddress := 0, endAddress := "", aAOBPattern*)
{
address := startAddress
if endAddress is not integer
endAddress := this.isTarget64bit ? (A_PtrSize = 8 ? 0x7FFFFFFFFFF : 0xFFFFFFFF) : 0x7FFFFFFF
MEM_COMMIT := 0x1000, MEM_MAPPED := 0x40000, MEM_PRIVATE := 0x20000
PAGE_NOACCESS := 0x01, PAGE_GUARD := 0x100
if !patternSize := this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
return -10
while address <= endAddress
{
if !this.VirtualQueryEx(address, aInfo)
return -1
if A_Index = 1
aInfo.RegionSize -= address - aInfo.BaseAddress
if (aInfo.State = MEM_COMMIT)
&& !(aInfo.Protect & (PAGE_NOACCESS | PAGE_GUARD))
&& aInfo.RegionSize >= patternSize
&& (result := this.PatternScan(address, aInfo.RegionSize, patternMask, AOBBuffer))
{
if result < 0
return -2
else if (result + patternSize - 1 <= endAddress)
return result
else return 0
}
address += aInfo.RegionSize
}
return 0
}
rawPatternScan(byRef buffer, sizeOfBufferBytes := "", startOffset := 0, aAOBPattern*)
{
if !this.getNeedleFromAOBPattern(patternMask, AOBBuffer, aAOBPattern*)
return -10
if (sizeOfBufferBytes + 0 = "" || sizeOfBufferBytes <= 0)
sizeOfBufferBytes := VarSetCapacity(buffer)
if (startOffset + 0 = "" || startOffset < 0)
startOffset := 0
return this.bufferScanForMaskedPattern(&buffer, sizeOfBufferBytes, patternMask, &AOBBuffer, startOffset)
}
getNeedleFromAOBPattern(byRef patternMask, byRef needleBuffer, aAOBPattern*)
{
patternMask := "", VarSetCapacity(needleBuffer, aAOBPattern.MaxIndex())
for i, v in aAOBPattern
patternMask .= (v + 0 = "" ? "?" : "x"), NumPut(round(v), needleBuffer, A_Index - 1, "UChar")
return round(aAOBPattern.MaxIndex())
}
VirtualQueryEx(address, byRef aInfo)
{
if (aInfo.__Class != "_ClassMemory._MEMORY_BASIC_INFORMATION")
aInfo := new this._MEMORY_BASIC_INFORMATION()
return aInfo.SizeOfStructure = DLLCall("VirtualQueryEx"
, "Ptr", this.hProcess
, "Ptr", address
, "Ptr", aInfo.pStructure
, "Ptr", aInfo.SizeOfStructure
, "Ptr")
}
patternScan(startAddress, sizeOfRegionBytes, byRef patternMask, byRef needleBuffer)
{
if !this.readRaw(startAddress, buffer, sizeOfRegionBytes)
return -1
if (offset := this.bufferScanForMaskedPattern(&buffer, sizeOfRegionBytes, patternMask, &needleBuffer)) >= 0
return startAddress + offset
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
return -1
if (sizeOfHayStackBytes > 0)
return DllCall(p, "Ptr", hayStackAddress, "UInt", sizeOfHayStackBytes, "Ptr", needleAddress, "UInt", needleSize, "AStr", patternMask, "UInt", startOffset, "cdecl int")
return -2
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
return p
DllCall("GlobalFree", "ptr", p)
return
}
class _MEMORY_BASIC_INFORMATION
{
__new()
{
if !this.pStructure := DllCall("GlobalAlloc", "UInt", 0, "Ptr", this.SizeOfStructure := A_PtrSize = 8 ? 48 : 28, "Ptr")
return ""
return this
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
,    "Type": {"Offset": 40, "Type": "UInt"} }
:   {  "BaseAddress": {"Offset": 0, "Type": "UInt"}
,   "AllocationBase": {"Offset": 4, "Type": "UInt"}
,   "AllocationProtect": {"Offset": 8, "Type": "UInt"}
,   "RegionSize": {"Offset": 12, "Type": "UInt"}
,   "State": {"Offset": 16, "Type": "UInt"}
,   "Protect": {"Offset": 20, "Type": "UInt"}
,   "Type": {"Offset": 24, "Type": "UInt"} }
if aLookUp.HasKey(key)
return numget(this.pStructure+0, aLookUp[key].Offset, aLookUp[key].Type)
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
,    "Type": {"Offset": 40, "Type": "UInt"} }
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
return value
}
}
Ptr()
{
return this.pStructure
}
sizeOf()
{
return this.SizeOfStructure
}
}
}
lua_LoadDLL(dll)
{
return, DllCall("LoadLibrary", "str", dll)
}
lua_UnloadDLL(hDll)
{
DllCall("FreeLibrary", "UInt", hDll)
}
lua_atPanic(ByRef l, panicf)
{
Return, DllCall("lua51\lua_atPanic", "UInt", L, "UInt", panicF, "Cdecl")
}
lua_call(ByRef l, nargs, nresults)
{
Return, DllCall("lua51\lua_pcall", "UInt", l, "Int", nargs, "Int", nresults, "Cdecl")
}
lua_checkstack(ByRef l, extra)
{
Return, DllCall("lua51\lua_checkstack", "UInt", l, "Int", extra, "Cdecl Int")
}
lua_close(ByRef l)
{
Return, DllCall("lua51\lua_close", "UInt", l, "Cdecl")
}
lua_concat(ByRef l, extra)
{
Return, DllCall("lua51\lua_concat", "UInt", l, "Int", extra, "Cdecl")
}
lua_cpcall(ByRef l, func, ByRef ud)
{
Return, DllCall("lua51\lua_cpcall", "UInt", l, "UInt", func, "UInt", ud, "Cdecl Int")
}
lua_createtable(ByRef l, narr, nrec)
{
Return, DllCall("lua51\lua_createtable", "UInt", l, "Int", narr, "Int", nrec, "Cdecl")
}
lua_dump(ByRef l, writer, ByRef data)
{
Return, DllCall("lua51\lua_dump", "UInt", l, "UInt", writer, "UInt", data, "Cdecl Int")
}
lua_equal(ByRef l, index1, index2)
{
Return, DllCall("lua51\lua_equal", "UInt", l, "Int", index1, "Int", index2, "Cdecl Int")
}
lua_error(ByRef l)
{
Return, DllCall("lua51\lua_error", "UInt", l, "Cdecl Int")
}
lua_gc(ByRef l, what, data)
{
Return, DllCall("lua51\lua_gc", "UInt", l, "Int", what, "Int", data, "Cdecl Int")
}
lua_getfenv(ByRef l, index)
{
Return, DllCall("lua51\lua_getfenv", "UInt", l, "Int", index, "Cdecl")
}
lua_getfield(ByRef L, index, name)
{
Return, DllCall("lua51\lua_getfield", "UInt", L, "Int", index, "Str", name, "Cdecl")
}
lua_getglobal(ByRef L, name)
{
Return, lua_getfield(L, -10002, name)
}
lua_getmetatable(ByRef L, index)
{
Return, DllCall("lua51\lua_getmetatable", "UInt", L, "Int", index, "Cdecl Int")
}
lua_gettable(ByRef L, index)
{
Return, DllCall("lua51\lua_gettable", "UInt", L, "Int", index, "Cdecl")
}
lua_gettop(ByRef l)
{
Return, DllCall("lua51\lua_gettop", "UInt", l, "Cdecl Int")
}
lua_insert(ByRef l, index)
{
Return, DllCall("lua51\lua_insert", "UInt", l, "Int", index, "Cdecl")
}
lua_isboolean(ByRef l, index)
{
Return, DllCall("lua51\lua_isboolean", "UInt", L, "Int", index, "Cdecl Int")
}
lua_iscfunction(ByRef l, index)
{
Return, DllCall("lua51\lua_iscfunction", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isfunction(ByRef l, index)
{
Return, DllCall("lua51\lua_isfunction", "UInt", L, "Int", index, "Cdecl Int")
}
lua_islightuserdata(ByRef l, index)
{
Return, DllCall("lua51\lua_islightuserdata", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isnil(ByRef l, index)
{
Return, DllCall("lua51\lua_isnil", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isnone(ByRef l, index)
{
Return, DllCall("lua51\lua_isnone", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isnoneornil(ByRef l, index)
{
Return, DllCall("lua51\lua_isnoneornil", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isnumber(ByRef l, index)
{
Return, DllCall("lua51\lua_isnumber", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isstring(ByRef l, index)
{
Return, DllCall("lua51\lua_isstring", "UInt", L, "Int", index, "Cdecl Int")
}
lua_istable(ByRef l, index)
{
Return, DllCall("lua51\lua_istable", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isthread(ByRef l, index)
{
Return, DllCall("lua51\lua_isthread", "UInt", L, "Int", index, "Cdecl Int")
}
lua_isuserdata(ByRef l, index)
{
Return, DllCall("lua51\lua_isuserdata", "UInt", L, "Int", index, "Cdecl Int")
}
lua_lessthan(ByRef l, index)
{
Return, DllCall("lua51\lua_lessthan", "UInt", L, "Int", index, "Cdecl Int")
}
lua_load(ByRef l, reader, ByRef data, ByRef chunkname)
{
Return, DllCall("lua51\lua_load", "UInt", L, "UInt", reader, "UInt", data, "UInt", chunkname, "Cdecl Int")
}
lua_newstate(f, ByRef ud)
{
Return, DllCall("lua51\lua_newstate", "UInt", f, "UInt", ud, "Cdecl UInt")
}
lua_newtable(ByRef l)
{
Return, lua_createTable(l, 0, 0)
}
lua_newthread(ByRef l)
{
Return, DllCall("lua51\lua_newthread", "UInt", l, "Cdecl UInt")
}
lua_next(ByRef l, index)
{
Return, DllCall("lua51\lua_next", "UInt", L, "Int", index, "Cdecl Int")
}
lua_objlen(ByRef l, index)
{
Return, DllCall("lua51\lua_objlen", "UInt", L, "Int", index, "Cdecl Int")
}
lua_pcall(ByRef l, nargs, nresults, errfunc)
{
Return, DllCall("lua51\lua_pcall", "UInt", l, "Int", nargs, "Int", nresults, "UInt", errfunc, "Cdecl")
}
lua_pop(ByRef l, no)
{
Return, DllCall("lua51\lua_pop", "UInt", l, "Int", no, "Cdecl")
}
lua_pushboolean(ByRef l, bool)
{
Return, DllCall("lua51\lua_pushboolean", "UInt", l, "Int", bool, "Cdecl")
}
lua_pushcclosure(ByRef L, funcAddr, n)
{
Return, DllCall("lua51\lua_pushcclosure", "UInt", L, "UInt", funcAddr, "Int", n, "Cdecl")
}
lua_pushcfunction(ByRef L, funcAddr)
{
Return, DllCall("lua51\lua_pushcclosure", "UInt", L, "UInt", funcAddr, "Int", 0, "Cdecl")
}
lua_pushinteger(ByRef l, int)
{
Return, DllCall("lua51\lua_pushinteger", "UInt", l, "Int", int, "Cdecl")
}
lua_pushlightuserdata(ByRef l, ByRef p)
{
Return, DllCall("lua51\lua_pushlightuserdata", "UInt", l, "UInt", p, "Cdecl")
}
lua_pushliteral(ByRef l, ByRef str)
{
Return, DllCall("lua51\lua_pushliteral", "UInt", l, "UInt", str, "Cdecl")
}
lua_pushlstring(ByRef l, ByRef str, len)
{
Return, DllCall("lua51\lua_pushlstring", "UInt", l, "UInt", str, "Int", len, "Cdecl")
}
lua_pushnil(ByRef l)
{
Return, DllCall("lua51\lua_pushnil", "UInt", l, "Cdecl")
}
lua_pushnumber(ByRef l, no)
{
Return, DllCall("lua51\lua_pushnumber", "UInt", l, "Double", no, "Cdecl")
}
lua_pushstring(ByRef l, ByRef str)
{
Return, DllCall("lua51\lua_pushstring", "UInt", l, "Str", str, "Cdecl")
}
lua_pushthread(ByRef l)
{
Return, DllCall("lua51\lua_pushthread", "UInt", l, "Cdecl")
}
lua_pushvalue(ByRef l, index)
{
Return, DllCall("lua51\lua_pushvalue", "UInt", l, "Int", index, "Cdecl")
}
lua_rawequal(ByRef l, index1, index2)
{
Return, DllCall("lua51\lua_rawequal", "UInt", l, "Int", index1, "Int", index2, "Cdecl Int")
}
lua_rawget(ByRef l, index)
{
Return, DllCall("lua51\lua_rawget", "UInt", l, "Int", index, "Cdecl")
}
lua_rawgeti(ByRef l, index, n)
{
Return, DllCall("lua51\lua_rawgeti", "UInt", l, "Int", index, "Int", n, "Cdecl")
}
lua_rawset(ByRef l, index)
{
Return, DllCall("lua51\lua_rawset", "UInt", l, "Int", index, "Cdecl")
}
lua_rawseti(ByRef l, index, n)
{
Return, DllCall("lua51\lua_rawseti", "UInt", l, "Int", index, "Int", n, "Cdecl")
}
lua_register(ByRef l, name, funcAddr)
{
lua_pushcfunction(l, funcAddr)
lua_setglobal(l, name)
}
lua_remove(ByRef l, index)
{
Return, DllCall("lua51\lua_remove", "UInt", l, "Int", index, "Cdecl")
}
lua_replace(ByRef l, index)
{
Return, DllCall("lua51\lua_replace", "UInt", l, "Int", index, "Cdecl")
}
lua_resume(ByRef l, narg)
{
Return, DllCall("lua51\lua_resume", "UInt", l, "Int", narg, "Cdecl Int")
}
lua_setallocf(ByRef l, f, ByRef ud)
{
Return, DllCall("lua51\lua_setallocf", "UInt", l, "UInt", f, "UInt", ud, "Cdecl")
}
lua_setfenv(ByRef l, index)
{
Return, DllCall("lua51\lua_setfenv", "UInt", l, "Int", index, "Cdecl Int")
}
lua_setfield(ByRef L, index, name)
{
Return, DllCall("lua51\lua_setfield", "UInt", L, "Int", index, "Str", name, "Cdecl")
}
lua_setglobal(ByRef L, name)
{
Return, lua_setfield(L, -10002, name)
}
lua_setmetatable(ByRef L, index)
{
Return, DllCall("lua51\lua_setmetatable", "UInt", L, "Int", index, "Cdecl Int")
}
lua_settable(ByRef L, index)
{
Return, DllCall("lua51\lua_settable", "UInt", L, "Int", index, "Cdecl")
}
lua_settop(ByRef l, index)
{
Return, DllCall("lua51\lua_settop", "UInt", l, "Int", index, "Cdecl")
}
lua_status(ByRef l)
{
Return, DllCall("lua51\lua_status", "UInt", l, "Cdecl")
}
lua_toboolean(ByRef l, no)
{
Return, DllCall("lua51\lua_toboolean", "UInt", l, "Int", no, "Cdecl Int")
}
lua_tocfunction(ByRef l, no)
{
Return, DllCall("lua51\lua_tocfunction", "UInt", l, "Int", no, "Cdecl UInt")
}
lua_tointeger(ByRef l, no)
{
Return, DllCall("lua51\lua_tointeger", "UInt", l, "Int", no, "Cdecl Int")
}
lua_tolstring(ByRef l, no, size)
{
Return, DllCall("lua51\lua_tolstring", "UInt", l, "Int", no, "Int", size, "Cdecl Str")
}
lua_tonumber(ByRef l, no)
{
Return, DllCall("lua51\lua_tonumber", "UInt", l, "Int", no, "Cdecl Double")
}
lua_topointer(ByRef l, no)
{
Return, DllCall("lua51\lua_topointer", "UInt", l, "Int", no, "Cdecl UInt")
}
lua_tostring(ByRef l, no)
{
Return, lua_tolstring(l, no, 0)
}
lua_tothread(ByRef l, no)
{
Return, DllCall("lua51\lua_tothread", "UInt", l, "Int", no, "Cdecl UInt")
}
lua_touserdata(ByRef l, no)
{
Return, DllCall("lua51\lua_touserdata", "UInt", l, "Int", no, "Cdecl UInt")
}
lua_type(ByRef l, no)
{
Return, DllCall("lua51\lua_type", "UInt", l, "Int", no, "Cdecl Int")
}
lua_typename(ByRef l, tp)
{
Return, DllCall("lua51\lua_typename", "UInt", l, "Int", tp, "Cdecl Str")
}
lua_xmove(ByRef from, ByRef to, n)
{
Return, DllCall("lua51\lua_xmove", "UInt", from, "UInt", to, "Int", n, "Cdecl")
}
lua_yield(ByRef l, nresults)
{
Return, DllCall("lua51\lua_yield", "UInt", l, "Int", nresults, "Cdecl Int")
}
luaopen_base(ByRef l)
{
Return, DllCall("lua51\luaopen_base", "UInt", l, "Cdecl")
}
luaopen_package(ByRef l)
{
Return, DllCall("lua51\luaopen_package", "UInt", l, "Cdecl")
}
luaopen_string(ByRef l)
{
Return, DllCall("lua51\luaopen_string", "UInt", l, "Cdecl")
}
luaopen_table(ByRef l)
{
Return, DllCall("lua51\luaopen_table", "UInt", l, "Cdecl")
}
luaopen_math(ByRef l)
{
Return, DllCall("lua51\luaopen_math", "UInt", l, "Cdecl")
}
luaopen_io(ByRef l)
{
Return, DllCall("lua51\luaopen_io", "UInt", l, "Cdecl")
}
luaopen_os(ByRef l)
{
Return, DllCall("lua51\luaopen_os", "UInt", l, "Cdecl")
}
luaopen_debug(ByRef l)
{
Return, DllCall("lua51\luaopen_debug", "UInt", l, "Cdecl")
}
luaL_buffinit(ByRef l, ByRef Buffer)
{
Return, DllCall("lua51\luaL_buffinit", "UInt", l, "UInt", Buffer, "Cdecl")
}
luaL_callmeta(ByRef l, obj, ByRef e)
{
Return, DllCall("lua51\luaL_callmeta", "UInt", l, "Int", obj, "Str", e, "Cdecl Int")
}
luaL_checkany(ByRef l, narg)
{
Return, DllCall("lua51\luaL_checkany", "UInt", l, "Int", narg, "Cdecl")
}
luaL_checkint(ByRef l, no)
{
Return, DllCall("lua51\luaL_checkint", "UInt", l, "Int", no, "Cdecl Int")
}
luaL_checkinteger(ByRef l, no)
{
Return, DllCall("lua51\luaL_checkinteger", "UInt", l, "Int", no, "Cdecl Int")
}
luaL_checklong(ByRef l, no)
{
Return, DllCall("lua51\luaL_checklong", "UInt", l, "Int", no, "Cdecl Int")
}
luaL_checklstring(ByRef l, no, ByRef len)
{
Return, DllCall("lua51\luaL_checklstring", "UInt", l, "Int", no, "UInt", len, "Cdecl Str")
}
luaL_checknumber(ByRef l, no)
{
Return, DllCall("lua51\luaL_checknumber", "UInt", l, "Int", no, "Cdecl Int")
}
luaL_checkoption(ByRef l, no, ByRef def, ByRef lst)
{
Return, DllCall("lua51\luaL_checkoption", "UInt", l, "Int", no, "UInt", def, "UInt", lst, "Cdecl Int")
}
luaL_checkstack(ByRef l, no, ByRef msg)
{
Return, DllCall("lua51\luaL_checkstack", "UInt", l, "Int", no, "Str", msg, "Cdecl")
}
luaL_checkstring(ByRef l, narg)
{
Return, DllCall("lua51\luaL_checkstring", "UInt", l, "Int", narg, "Cdecl")
}
luaL_checktype(ByRef l, no, t)
{
Return, DllCall("lua51\luaL_checktype", "UInt", l, "Int", no, "Int", t, "Cdecl")
}
luaL_checkudata(ByRef l, no, ByRef tname)
{
Return, DllCall("lua51\luaL_checkudata", "UInt", l, "Int", no, "Str", tname, "Cdecl")
}
luaL_dofile(ByRef l, file)
{
luaL_loadfile(l, file)
Return % lua_pCall(l, 0, -1, 0)
}
luaL_dostring(ByRef l, ByRef str)
{
luaL_loadstring(l, str)
Return % lua_pCall(l, 0, -1, 0)
}
luaL_error(ByRef l, ByRef str)
{
Return, DllCall("lua51\luaL_error", "UInt", l, "Str", str, "Cdecl Int")
}
luaL_getmetafield(ByRef l, no, ByRef e)
{
Return, DllCall("lua51\luaL_getmetafield", "UInt", l, "Int", no, "Str", e, "Cdecl Int")
}
luaL_getmetatable(ByRef l, ByRef tname)
{
Return, DllCall("lua51\luaL_getmetatable", "UInt", l, "Str", tname, "Cdecl")
}
luaL_gsub(ByRef l, ByRef s, ByRef p, ByRef r)
{
Return, DllCall("lua51\luaL_gsub", "UInt", l, "UInt", s, "UInt", p, "UInt", r, "Cdecl Str")
}
luaL_loadbuffer(ByRef l, ByRef buff, sz, ByRef name)
{
Return, DllCall("lua51\luaL_loadbuffer", "UInt", l, "UInt", buff, "Int", sz, "Str", name, "Cdecl Int")
}
luaL_loadfile(ByRef l, file)
{
Return, DllCall("lua51\luaL_loadfile", "UInt", l, "Str", file, "Cdecl Int")
}
luaL_loadstring(ByRef l, ByRef s)
{
Return, DllCall("lua51\luaL_loadstring", "UInt", l, "Str", s, "Cdecl Int")
}
luaL_newmetatable(ByRef l, ByRef tname)
{
Return, DllCall("lua51\luaL_newmetatable", "UInt", l, "Str", tname, "Cdecl Int")
}
luaL_newstate()
{
Return, DllCall("lua51\luaL_newstate", "Cdecl")
}
luaL_openlibs(ByRef l)
{
Return, DllCall("lua51\luaL_openlibs", "UInt", l, "Cdecl")
}