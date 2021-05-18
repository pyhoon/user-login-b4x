B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip

Sub Class_Globals
	Private Root As B4XView
	#If B4J
	Private fx As JFX
	Private clx As clXToastMessage1
	#End If	
	#If B4i
	Dim hud As HUD
	#End If
	Private xui As XUI
	Private KVS As KeyValueStore
	Private Drawer As B4XDrawer
	Private B4XGifView1 As B4XGifView
	Public PageUser As B4XPageUser
	Public PagePassword As B4XPagePassword
	'Dim strMode As String	
	Private CLVL As CustomListView
	Private CLVM As CustomListView
	Private imgProfile As ImageView
	Private lblProfileName As Label
	Private lblMenuIcon As Label
	Private lblMenuText As Label
	Private pnlStatus As B4XView
	Private lblName As Label
	Private btnMenu As Label
	#If B4J
	Private pnlBlur As Pane
	#Else
	Private pnlBlur As Panel
	#End If	
	Private lblViewUserName As Label
	Private lblViewUserLocation As Label
	Private txtViewUserLocation As B4XView
	Private lblViewUserStatus As Label
	Private pnlTop As B4XView
End Sub

Public Sub Initialize
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)	
	Root = Root1
	#If B4J
	clx.Initialize(Root)
	#End If
	Wait For (ShowSplashScreen) Complete (Unused As Boolean)	
	'CheckLogin
	'Root.LoadLayout("HomePage")
	Root.RemoveAllViews
	
	B4XPages.SetTitle(Me, "APP")
	Drawer.Initialize(Me, "Drawer", Root, 400dip)
	Drawer.LeftPanel.LoadLayout("LeftMenu")
	Drawer.CenterPanel.LoadLayout("HomePage")
	
	Wait For (KVS.GetMapAsync(Array("ApiKey", "Token"))) Complete (M As Map)
	If M.IsInitialized Then
		If M.ContainsKey("Token") Then
			Main.gUserToken = M.Get("Token")
		End If
		If M.ContainsKey("ApiKey") Then
			Main.gUserAPIKey = M.Get("ApiKey")
		End If
	End If
	
	If Main.gLogin = 0 Then
		If Main.gUserAPIKey <> "" Then
			GetToken
		Else
			LoadSlideMenu
			Drawer.LeftOpen = True
		End If
	Else
		'If Drawer.IsInitialized = False Then
		'	Drawer.Initialize(Me, "Drawer", Root, 200dip)
		'Drawer.LeftPanel.LoadLayout("LeftMenu")
		'Drawer.CenterPanel.LoadLayout("HomePage")
		'End If
		LoadSlideMenu
		GetProfile
		GetUserList
	End If

	PageUser.Initialize
	B4XPages.AddPage("Login", PageUser)
	B4XPages.AddPage("Register", PageUser)	
	B4XPages.AddPage("About", PageUser)
	
	PagePassword.Initialize
	B4XPages.AddPage("PasswordChange", PagePassword)
	B4XPages.AddPage("PasswordReset", PagePassword)
	'PageLogin.Initialize
	'B4XPages.AddPage("Login", PageLogin)
'	If Main.UID <> "" And Main.PWD <> "" Then
'		#If B4i
'		Main.NavControl.NavigationBarVisible = True
'		#End If
'		'Root.LoadLayout("HomePage")
'		Drawer.CenterPanel.LoadLayout("HomePage")
'		GetProfile
'	Else
'		#If B4i
'		Main.NavControl.NavigationBarVisible = False
'		#End If		
'		B4XPages.ShowPageAndRemovePreviousPages("Login")
'	End If
End Sub

Private Sub B4XPage_Appear
	If Drawer.IsInitialized And Main.gLogin = 1 Then
		LoadSlideMenu
		GetProfile
		GetUserList
	End If
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If Drawer.IsInitialized Then Drawer.Resize(Width, Height)
End Sub

Sub ShowSplashScreen As ResumableSub
	#If B4i
	Main.NavControl.NavigationBarVisible = False
	#End If	
	Root.LoadLayout("Splash")
	B4XPages.SetTitle(Me, "App")
	B4XGifView1.SetGif(File.DirAssets, "loading.gif")
	Sleep(2000)
	Return True
End Sub

Sub GetToken
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XMainPage] GetToken")
		Utility.ShowProgressDialog("Connecting to server...")
		job.Initialize("", Me)
		job.Download(Main.strURL & "user/connect")
		Wait For (job) JobDone(job As HttpJob)
		Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			Log(strData)
			job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Refreshing User Token...")
					Dim Map2 As Map
					Map2.Initialize
					Log("API Key=" & Main.gUserAPIKey)
					Map2.Put("key", Main.gUserAPIKey)
					jsn = Utility.Map2Json(Map2)
					job.Initialize("", Me)
					job.PostString(Main.strURL & "user/gettoken", jsn)
					Wait For (job) JobDone(job As HttpJob)
					Utility.HideProgressDialog
					If job.Success Then
						strData = job.GetString
						job.Release
						Log(strData)
						parser.Initialize(strData)
						If Utility.isArray(strData) Then
							List1 = parser.NextArray
							Map1 = List1.Get(0)
							If -1 = Map1.Get("result") Then
								If Map1.Get("message") = "Error-No-Result" Then
									'ShowToastMessage("Error: Invalid API key", False)
									' Try to relogin
									Main.gLogin = 0
									Main.gUserAPIKey = ""
									Main.gUserToken = ""
									' Delete Token
									KVS.DeleteAll
									Sleep(0)
									LoadSlideMenu
									Drawer.LeftOpen = True
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If Map1.Get("message") = "success" Then
								Main.gUserToken = Map1.Get("user_token")
								Main.gLogin = 1
								GetProfile
								GetUserList
							End If
							If Main.gUserToken = "" Then
								Log("Invalid User Token")
								ShowToastMessage("Error: Invalid User Token. Please contact the developer.", False)
								Return
							End If
							' Write to internal storage
							Dim User As Map = CreateMap("Token": Main.gUserToken)
							Wait For (KVS.PutMapAsync(User)) Complete (Success As Boolean)
							'Log(Success)
						Else
							job.Release
							#If B4i
							
							#Else
							strData = parser.NextValue
							Log(strData)
							#End If
							ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
						End If
					Else
						strError = job.ErrorMessage
						job.Release
						Log(strError)
						ShowConnectionError(strError)
					End If
				End If
			Else
				job.Release
				#If B4i
				
				#Else
				strData = parser.NextValue
				Log(strData)
				#End If
				ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
			End If
		Else
			strError = job.ErrorMessage
			job.Release
			Log(strError)
			ShowConnectionError(strError)
		End If
	Catch
		job.Release
		Log("[B4XMainPage] GetToken: " & LastException.Message)
		ShowToastMessage("Failed to get access token", False)
	End Try
End Sub

Sub GetProfile
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XMainPage] GetProfile")
		Utility.ShowProgressDialog("Connecting to server...")
		job.Initialize("", Me)
		job.Download(Main.strURL & "user/connect")
		Wait For (job) JobDone(job As HttpJob)
		Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			Log(strData)
			job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Retrieving User Profile...")
					Dim Map2 As Map
					Map2.Initialize
					'Map2.Put("key", Main.gUserAPIKey)
					Log("Token=" & Main.gUserToken)
					Map2.Put("token", Main.gUserToken)
					jsn = Utility.Map2Json(Map2)
					job.Initialize("", Me)
					job.PostString(Main.strURL & "user/getprofile", jsn)
					Wait For (job) JobDone(job As HttpJob)
					Utility.HideProgressDialog
					If job.Success Then
						strData = job.GetString
						job.Release
						Log(strData)
						parser.Initialize(strData)
						If Utility.isArray(strData) Then
							List1 = parser.NextArray
							Map1 = List1.Get(0)
							If -1 = Map1.Get("result") Then
								If Map1.Get("message") = "Error-No-Result" Or _
									 Map1.Get("message") = "Error-Invalid-Token" Then
									ShowToastMessage("Error: Invalid Access Token", False)
									ShowMsgBox("Please relogin", "Invalid Token")								
								Else If Map1.Get("message") = "Error-Not-Authorized" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								'Return
							End If
							If Map1.Get("message") = "success" Then
								Main.gUserName = Map1.Get("user_name")
								Main.gUserEmail = Map1.Get("user_email")
								Main.gUserLocation = Map1.Get("user_location")
							End If
							LoadSlideMenu
						Else
							job.Release
							#If B4i
							
							#Else
							strData = parser.NextValue
							Log(strData)
							#End If
							ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
						End If
					Else
						strError = job.ErrorMessage
						job.Release
						Log(strError)
						ShowConnectionError(strError)
					End If
				End If
			Else
				job.Release
				#If B4i
				
				#Else
				strData = parser.NextValue
				Log(strData)
				#End If
				ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
			End If
		Else
			strError = job.ErrorMessage
			job.Release
			Log(strError)
			ShowConnectionError(strError)
		End If
	Catch
		job.Release
		Log("[B4XMainPage] GetProfile: " & LastException.Message)
		ShowToastMessage("Failed to get profile", False)
	End Try
End Sub

Sub GetUserList
	Dim parser As JSONParser
	Dim Job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Dim Rows As Int
	Dim intListUserID As Int
	Dim strListUserName As String
	Dim strListUserStatus As String
	Try
		If Main.gUserToken = "" Then
			ShowToastMessage("Error: Invalid Token. Try Login again.", False)			
			Return
		End If
		Log("[B4XMainPage] GetUserList")
		Job.Initialize("", Me)
		Utility.ShowProgressDialog("Connecting to server...")
		Job.Download(Main.strURL & "user/connect")
		Wait For (Job) JobDone(Job As HttpJob)
		Utility.HideProgressDialog
		If Job.Success Then
			strData = Job.GetString
			'Log(strData)
			Job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Retrieving data...")
					Dim Map2 As Map
					Map2.Initialize
					'Map2.Put("key", Main.gUserAPIKey)
					Log("Token=" & Main.gUserToken)
					Map2.Put("token", Main.gUserToken)
					jsn = Utility.Map2Json(Map2)
					Job.Initialize("", Me)
					Job.PostString(Main.strURL & "user/view/all", jsn)
					Wait For (Job) JobDone(Job As HttpJob)
					Utility.HideProgressDialog
					If Job.Success Then
						strData = Job.GetString
						Log(strData)
						parser.Initialize(strData)
						If Utility.isArray(strData) Then
							List1 = parser.NextArray
							Map1 = List1.Get(0)
							If -1 = Map1.Get("result") Then
								If Map1.Get("message") = "Error-No-Result" Then
									ShowToastMessage("Message: No Results", False)
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else If Map1.Get("message") = "Error-Invalid-Token" Then
									ShowToastMessage("Error: Invalid Access Token", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If List1.Size < 1 Then
								Return
							End If
							Rows = List1.Size
							CLVM.Clear
							For i = 0 To Rows - 1
								Map1 = List1.Get(i)
								intListUserID = Map1.Get("result")
								strListUserName = Map1.Get("user_name")
								strListUserStatus = Map1.Get("online")
								CLVM.Add(CreateList(strListUserName, strListUserStatus, CLVM.AsView.Width), intListUserID)
							Next
						Else
							#If B4i
							
							#Else
							strData = parser.NextValue
							Log(strData)
							#End If
							ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
						End If
					Else
						strError = Job.ErrorMessage
						Job.Release
						Log(strError)
						ShowConnectionError(strError)
					End If
				End If
			Else
				#If B4i
				
				#Else
				strData = parser.NextValue
				Log(strData)
				#End If
				ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
			End If
		Else
			strError = Job.ErrorMessage
			Job.Release
			Log(strError)
			ShowConnectionError(strError)
		End If
	Catch
		Job.Release
		Log("[B4XMainPage] GetUserList: " & LastException.Message)
		ShowToastMessage("Failed to retrieve data", False)
	End Try
End Sub

Sub GetUserInfo(id As Int)
	Dim parser As JSONParser
	Dim Job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		If Main.gUserToken = "" Then
			ShowToastMessage("Error: Invalid Token. Try Login again.", False)
			Return
		End If
		Log("[B4XMainPage] GetUserInfo")
		Job.Initialize("", Me)
		Utility.ShowProgressDialog("Connecting to server...")
		Job.Download(Main.strURL & "user/connect")
		Wait For (Job) JobDone(Job As HttpJob)
		Utility.HideProgressDialog
		If Job.Success Then
			strData = Job.GetString
			'Log(strData)
			Job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Retrieving data...")
					Dim Map2 As Map
					Map2.Initialize
					'Map2.Put("key", Main.gUserAPIKey)
					Log("Token=" & Main.gUserToken)
					Map2.Put("token", Main.gUsertoken)
					jsn = Utility.Map2Json(Map2)
					'Log(jsn)
					Job.Initialize("", Me)
					Job.PostString(Main.strURL & "user/view/" & id, jsn)
					Wait For (Job) JobDone(Job As HttpJob)
					Utility.HideProgressDialog
					If Job.Success Then
						strData = Job.GetString
						Log(strData)
						parser.Initialize(strData)
						If Utility.isArray(strData) Then
							List1 = parser.NextArray
							Map1 = List1.Get(0)
							If -1 = Map1.Get("result") Then
								If Map1.Get("message") = "Error-No-Result" Then
									ShowToastMessage("Message: No Results", False)
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If List1.Size < 1 Then
								Return
							End If
							Map1 = List1.Get(0)
							lblViewUserName.Text = Map1.Get("user_name")
							txtViewUserLocation.Text = Map1.Get("user_location")
							If Map1.Get("online") = "Y" Then
								lblViewUserStatus.Text = "Online"
								#If B4J
								lblViewUserStatus.TextColor = fx.Colors.RGB(50, 205, 50)
								#Else
								lblViewUserStatus.TextColor = Colors.RGB(50, 205, 50)
								#End If								
							Else
								lblViewUserStatus.Text = "Offline"
								#If B4J
								lblViewUserStatus.TextColor = fx.Colors.RGB(105, 105, 105)
								#Else
								lblViewUserStatus.TextColor = Colors.RGB(105, 105, 105)
								#End If									
							End If
							pnlBlur.Visible = True
							Drawer.GestureEnabled = False
							#If B4i
							
							#Else
							btnMenu.Enabled = False
							#End If							
						Else
							#If B4i
							
							#Else
							strData = parser.NextValue
							Log(strData)
							#End If
							ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
						End If
					Else
						strError = Job.ErrorMessage
						Job.Release
						Log(strError)
						ShowConnectionError(strError)
					End If
				End If
			Else
				#If B4i
				
				#Else
				strData = parser.NextValue
				Log(strData)
				#End If
				ShowToastMessage("Error: Uncaught error" & CRLF & strData, False)
			End If
		Else
			strError = Job.ErrorMessage
			Job.Release
			Log(strError)
			ShowConnectionError(strError)
		End If
	Catch
		Job.Release
		Log("[B4XMainPage] GetUserInfo: " & LastException.Message)
		ShowToastMessage("Failed to retrieve data", False)
	End Try
End Sub

#If B4A
Sub btnMenu_Click
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If
#If B4J
Sub btnMenu_MouseClicked (EventData As MouseEvent)
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If

Sub CLVL_ItemClick (Index As Int, Value As Object)
	Drawer.LeftOpen = False
	Select Case Value
		Case "Log in"
			'If PageUser.IsInitialized = False Then PageUser.Initialize
			'B4XPages.AddPage("Login", PageUser)
			PageUser.strMode = "Login"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("Login")
			#Else			
			B4XPages.ShowPage("Login")
			#End If
		Case "Register"
			'If PageUser.IsInitialized = False Then PageUser.Initialize
			'B4XPages.AddPage("Register", PageUser)
			PageUser.strMode = "Register"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("Register")
			#Else			
			B4XPages.ShowPage("Register")
			#End If
		Case "Change Password"
			'If PagePassword.IsInitialized = False Then PagePassword.Initialize
			'B4XPages.AddPage("PasswordChange", PagePassword)
			PagePassword.strMode = "Change Password"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("PasswordChange")
			#Else
			B4XPages.ShowPage("PasswordChange")
			#End If						
		Case "About Me"
			'If PageUser.IsInitialized = False Then PageUser.Initialize
			'B4XPages.AddPage("About", PageUser)
			PageUser.strMode = "About"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("About")
			#Else			
			B4XPages.ShowPage("About")
			#End If			
		Case "Log out"
			Main.gLogin = 0
			Main.gUserAPIKey = ""
			Main.gUserToken = ""
			' Delete Token
			KVS.DeleteAll
			Sleep(0)
			CLVM.Clear
			LoadSlideMenu
			Drawer.LeftOpen = True
End Select
End Sub

Sub LoadSlideMenu
	'Log("LoadSlideMenu")
	CLVL.Clear
	If Main.gLogin = 0 Then
		CLVL.Add(CreateMenu(Chr(0xF090), "Log in", CLVL.AsView.Width), "Log in")
		CLVL.Add(CreateMenu(Chr(0xF234), "Register", CLVL.AsView.Width), "Register")
	Else
		lblProfileName.Text = Main.gUserName
		CLVL.Add(CreateMenu(Chr(0xF05A), "About Me", CLVL.AsView.Width), "About Me")
		CLVL.Add(CreateMenu(Chr(0xF013), "Change Password", CLVL.AsView.Width), "Change Password")
		CLVL.Add(CreateMenu(Chr(0xF08B), "Log out", CLVL.AsView.Width), "Log out")
	End If
	CLVL.AnimationDuration = 0
	' Reference: https://www.b4x.com/android/forum/threads/b4x-xui-create-a-round-image.85102/
	Dim xIV As B4XView = imgProfile
	Dim img As B4XBitmap = xui.LoadBitmapResize(File.DirAssets, "default.png", imgProfile.Width, imgProfile.Height, False)
	xIV.SetBitmap(CreateRoundBitmap(img, xIV.Width))
End Sub

Private Sub CreateMenu(MenuIcon As String, MenuText As String, Width As Long) As B4XView
	Dim Height As Int = 60dip
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, Height)
	p.LoadLayout("MenuItem")
	lblMenuIcon.Text = MenuIcon
	lblMenuText.Text = MenuText
	Return p
End Sub

Private Sub CreateList(ListText As String, ListStatus As String, Width As Long) As B4XView
	Dim Height As Int = 60dip
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, Height)	
	p.LoadLayout("ListItem")
	lblName.Text = ListText
	If ListStatus = "Y" Then		
		#If B4J
		pnlStatus.Color = xui.Color_Green
		#Else
		pnlStatus.Color = Colors.Green
		#End If
	Else
		#If B4J
		pnlStatus.Color = xui.Color_Gray
		#Else
		pnlStatus.Color = Colors.Gray
		#End If
	End If
	Return p
End Sub

'xui is a global XUI variable.
Sub CreateRoundBitmap (Input As B4XBitmap, Size As Int) As B4XBitmap
	If Input.Width <> Input.Height Then
		'if the image is not square then we crop it to be a square.
		Dim l As Int = Min(Input.Width, Input.Height)
		Input = Input.Crop(Input.Width / 2 - l / 2, Input.Height / 2 - l / 2, l, l)
	End If
	Dim c As B4XCanvas
	Dim xview As B4XView = xui.CreatePanel("")
	xview.SetLayoutAnimated(0, 0, 0, Size, Size)
	c.Initialize(xview)
	Dim path As B4XPath
	path.InitializeOval(c.TargetRect)
	c.ClipPath(path)
	c.DrawBitmap(Input.Resize(Size, Size, False), c.TargetRect)
	c.RemoveClip
	c.DrawCircle(c.TargetRect.CenterX, c.TargetRect.CenterY, c.TargetRect.Width / 2 - 1dip, xui.Color_LightGray, False, 2dip) 'comment this line to remove the border
	c.Invalidate
	Dim res As B4XBitmap = c.CreateBitmap
	c.Release
	Return res
End Sub

Sub ShowConnectionError(strError As String)
	If strError.Contains("Unable to resolve host") Then
		ShowToastMessage("Connection failed.", False)
	Else If strError.Contains("timeout") Then
		ShowToastMessage("Connection timeout.", False)
	Else
		ShowToastMessage("Error: " & strError, True)
	End If
End Sub

Sub ShowToastMessage(Message As String, LongDuration As Boolean)
	#If B4A
	ToastMessageShow(Message, LongDuration)
	#End If
	#If B4i
	hud.ToastMessageShow(Message, LongDuration)
	#End If
	#If B4J
	clx.Show(Message, LongDuration)
	#End If
End Sub

Sub ShowMsgBox(Message As String, Title As String)
#If B4J
	xui.MsgboxAsync(Message, Title)
#Else If B4i
	Msgbox(Message, Title)
#Else
	MsgboxAsync(Message, Title)
#End If	
End Sub

Sub CLVM_ItemClick (Index As Int, Value As Object)
	GetUserInfo(Value)
End Sub

#If B4J
Sub lblClose_MouseClicked (EventData As MouseEvent)
	pnlBlur.Visible = False
	Drawer.GestureEnabled = True
	btnMenu.Enabled = True
End Sub

Sub lblClose_MousePressed (EventData As MouseEvent)
	pnlBlur.Visible = False
	Drawer.GestureEnabled = True
	btnMenu.Enabled = True
End Sub

Sub pnlBlur_MouseClicked (EventData As MouseEvent)
	Log("NoScroll")
End Sub

Sub NoScroll_MouseClicked (EventData As MouseEvent)
	Log("NoScroll")
End Sub
#Else
Sub lblClose_Click
	pnlBlur.Visible = False
	Drawer.GestureEnabled = True
	#If B4i
	
	#Else
	btnMenu.Enabled = True	
	#End If	
End Sub
Sub NoScroll_Click
'	Log("NoScroll")
End Sub
#End If

Sub BtnClose_Click
	pnlBlur.Visible = False
	Drawer.GestureEnabled = True
	#If B4i
	
	#Else
	btnMenu.Enabled = True	
	#End If	
End Sub