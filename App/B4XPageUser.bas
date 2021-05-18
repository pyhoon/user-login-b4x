B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	#If B4i
	Dim hud As HUD
	#End If
	#If B4J
	Private fx As JFX
	Private clx As clXToastMessage1
	#End If
	'Public PagePassword As B4XPagePassword
	Private txtUserEmail As B4XFloatTextField
	Private txtPassword As B4XFloatTextField
	Private txtPassword1 As B4XFloatTextField
	Private txtPassword2 As B4XFloatTextField
	Private txtUserName As B4XFloatTextField
	Private txtUserLocation As B4XFloatTextField
	Private BtnSubmit As Button
	Private BtnReset As Button
	Private btnCancel As Button
	Private xui As XUI
	Private KVS As KeyValueStore	
	Private lblUserEmail As Label
	Private lblUserLocation As Label
	Private lblUserName As Label	
	Private imgUser As ImageView
	Dim strMode As String	
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	#If B4J
	clx.Initialize(Root)
	#End If
	'Root.LoadLayout("UserLogin")
'	If Main.DEV Then
'		txtUserEmail.Text = Main.DEMO_EMAIL
'		txtPassword.Text = Main.DEMO_PASSWORD
'	Else
'		txtUserEmail.Text = Main.gUserEmail
'	End If
End Sub

Private Sub B4XPage_Appear
	SelectMode
End Sub

Sub SelectMode
	Select Case strMode
		Case "Login"
			Root.RemoveAllViews
			Root.LoadLayout("UserLogin")
			'IME.SetLengthFilter(txtUserEmail, 200)
			'IME.SetLengthFilter(txtPassword, 20)
			If Main.DEV Then
				txtUserEmail.Text = Main.DEMO_EMAIL
				txtPassword.Text = Main.DEMO_PASSWORD
			Else
				txtUserEmail.Text = Main.gUserEmail
			End If
		Case "Register"
			Root.RemoveAllViews
			Root.LoadLayout("UserRegister")
			'IME.SetLengthFilter(txtUserName, 200)
			'IME.SetLengthFilter(txtUserEmail, 200)
			'IME.SetLengthFilter(txtUserPassword1, 20)
			'IME.SetLengthFilter(txtUserPassword2, 20)
			If Main.DEV Then
				txtUserName.Text = Main.DEMO_NAME
				txtUserEmail.Text = Main.DEMO_EMAIL
				txtPassword1.Text = Main.DEMO_PASSWORD
				txtPassword2.Text = Main.DEMO_PASSWORD
			End If
		Case "About"
			Root.RemoveAllViews
			Root.LoadLayout("About")
			lblUserName.Text = Main.gUserName
			lblUserEmail.Text = Main.gUserEmail
			lblUserLocation.Text = Main.gUserLocation
			' Reference: https://www.b4x.com/android/forum/threads/b4x-xui-create-a-round-image.85102/
			Dim xIV As B4XView = imgUser
			Dim img As B4XBitmap = xui.LoadBitmapResize(File.DirAssets, "default.png", imgUser.Width, imgUser.Height, False)
			xIV.SetBitmap(CreateRoundBitmap(img, xIV.Width))
	End Select
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.

Sub RegisterUser
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XPageUser] RegisterUser")
		Dim Map2 As Map
		Map2.Initialize
		Map2.Put("name", txtUserName.Text.Trim)
		Map2.Put("eml", txtUserEmail.Text.Trim)
		Map2.Put("pwd", txtPassword1.Text.Trim)
		jsn = Utility.Map2Json(Map2)
		job.Initialize("", Me)
		job.PostString(Main.strURL & "user/register", jsn)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			job.Release
			Log(strData)
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				Dim List1 As List
				Dim Map1 As Map
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If -1 = Map1.Get("result") Then
					If Map1.Get("message") = "Error-No-Result" Then
						ShowToastMessage("Error: Invalid Password", False)					
					Else If Map1.Get("message") = "Error-No-Value" Then
						ShowToastMessage("Error: Invalid Parameters", False)
					Else If Map1.Get("message") = "Error-Email-Used" Then
						ShowMsgBox("Email already registered!", "E R R O R")
					Else
						ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
					End If
					Return
				End If
				If strMode = "Register" Then
					Main.gUserEmail = txtUserEmail.Text.Trim
				End If
				ShowMsgBox("Please check your email for account activation!", "Registration Successful")
				strMode = "Login"
				SelectMode
			Else
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
		Log("[B4XPageUser] RegisterUser: " & LastException.Message)
		ShowToastMessage("Failed to register user", False)
	End Try
End Sub

Sub LoginUser
	Dim parser As JSONParser
	Dim Job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Dim strUserEmail As String = txtUserEmail.Text.Trim
	Dim strUserPassword As String = txtPassword.Text.Trim
	Try
		Log("[B4XPageUser] LoginUser")
		Utility.ShowProgressDialog("Connecting to server...")
		Job.Initialize("", Me)
		Job.Download(Main.strURL & "user/connect")
		Wait For (Job) JobDone(Job As HttpJob)
		Utility.HideProgressDialog
		If Job.Success Then
			strData = Job.GetString
			Job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					' Download Info
					Utility.ShowProgressDialog("Downloading info...")
					Dim Map2 As Map
					Map2.Initialize
					Map2.Put("eml", strUserEmail)
					Map2.Put("pwd", strUserPassword)
					jsn = Utility.Map2Json(Map2)
					Job.Initialize("", Me)
					Job.PostString(Main.strURL & "user/login", jsn)
					Wait For (Job) JobDone(Job As HttpJob)
					Utility.HideProgressDialog
					If Job.Success Then
						strData = Job.GetString
						Job.Release
						Log(strData)
						parser.Initialize(strData)
						If Utility.isArray(strData) Then
							List1 = parser.NextArray
							Map1 = List1.Get(0)
							If -1 = Map1.Get("result") Then
								If Map1.Get("message") = "Error-No-Result" Then
									ShowToastMessage("Error: Invalid Password", False)
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else If Map1.Get("message") = "Error-Not-Activated" Then
									ShowToastMessage("Error: Your account is not activated", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If Map1.Get("message") = "success" Then
								Main.gUserName = Map1.Get("user_name")
								Main.gUserEmail = Map1.Get("user_email")
								Main.gUserLocation = Map1.Get("user_location")
								Main.gUserAPIKey = Map1.Get("user_api_key")
								Main.gUserToken = Map1.Get("user_token")
								'Main.gLogin = 1
								' Write to internal storage
								Dim User As Map = CreateMap("ApiKey": Main.gUserAPIKey, "Token": Main.gUserToken)
								Wait For (KVS.PutMapAsync(User)) Complete (Success As Boolean)
								Log(Success)
								'KVS.PutMapAsync(User)
							End If
							If Main.gUserAPIKey = "" Then
								'Utility.ShowProgressDialog("Getting API Key...")
								Dim Map2 As Map
								Map2.Initialize
								Map2.Put("eml", strUserEmail)
								Map2.Put("pwd", strUserPassword)
								jsn = Utility.Map2Json(Map2)
								Job.Initialize("", Me)
								Job.PostString(Main.strURL & "user/getapikey", jsn)
								Wait For (Job) JobDone(Job As HttpJob)
								'Utility.HideProgressDialog
								If Job.Success Then
									strData = Job.GetString
									Job.Release
									Log(strData)
									parser.Initialize(strData)
									If Utility.isArray(strData) Then
										List1 = parser.NextArray
										Map1 = List1.Get(0)
										If -1 = Map1.Get("result") Then
											If Map1.Get("message") = "Error-No-Result" Then
												ShowToastMessage("Error: Invalid Email or Password", False)
											Else If Map1.Get("message") = "Error-No-Value" Then
												ShowToastMessage("Error: Invalid Parameters", False)
											Else
												ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
											End If
											Return
										End If
										If Map1.Get("message") = "success" Then
											Main.gUserAPIKey = Map1.Get("user_api_key")
										End If
										If Main.gUserAPIKey = "" Then
											Log("Invalid API Key")
											ShowToastMessage("Error: Invalid API Key. Please contact the developer.", False)
											Return
										End If
										' Write to internal storage
										Dim User As Map = CreateMap("ApiKey": Main.gUserAPIKey)
										Wait For (KVS.PutMapAsync(User)) Complete (Success As Boolean)
										Log(Success)
									Else
										Job.Release
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
									'CommonUtility.ShowConnectionError(strError)
								End If
							End If
							If Main.gUserToken = "" Then
								'Utility.ShowProgressDialog("Refreshing User Token...")
								Dim Map3 As Map
								Map3.Initialize
								Map3.Put("key", Main.gUserAPIKey)
								jsn = Utility.Map2Json(Map3)
								Job.Initialize("", Me)
								Job.PostString(Main.strURL & "user/gettoken", jsn)
								Wait For (Job) JobDone(Job As HttpJob)
								'Utility.HideProgressDialog
								If Job.Success Then
									strData = Job.GetString
									Job.Release
									Log(strData)
									parser.Initialize(strData)
									If Utility.isArray(strData) Then
										List1 = parser.NextArray
										Map1 = List1.Get(0)
										If -1 = Map1.Get("result") Then
											If Map1.Get("message") = "Error-No-Result" Then
												ShowToastMessage("Error: Invalid API key", False)
											Else If Map1.Get("message") = "Error-No-Value" Then
												ShowToastMessage("Error: Invalid Parameters", False)
											Else
												ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
											End If
											Return
										End If
										If Map1.Get("message") = "success" Then
											Main.gUserName = Map1.Get("user_name")
											Main.gUserEmail = Map1.Get("user_email")
											Main.gUserLocation = Map1.Get("user_location")
											Main.gUserAPIKey = Map1.Get("user_api_key")
											Main.gUserToken = Map1.Get("user_token")
											'Main.gLogin = 1
											' Write to internal storage
											Dim User As Map = CreateMap("ApiKey": Main.gUserAPIKey, "Token": Main.gUserToken)
											Wait For (KVS.PutMapAsync(User)) Complete (Success As Boolean)
											Log(Success)
										End If

										' Write to internal storage
										Dim User As Map = CreateMap("Token": Main.gUserToken)
										Wait For (KVS.PutMapAsync(User)) Complete (Success As Boolean)
										Log(Success)
									Else
										Job.Release
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
									'CommonUtility.ShowConnectionError(strError)
								End If
							End If
							Main.gLogin = 1
							ShowToastMessage("Login successful", False)
							'Activity.Finish
							'B4XPages.ClosePage(Me)
							'B4XPages.ShowPageAndRemovePreviousPages(B4XPages.GetPageId(B4XPages.MainPage))
							B4XPages.ShowPageAndRemovePreviousPages("MainPage")
							'Root.LoadLayout("HomePage")
						Else
							Job.Release
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
						'CommonUtility.ShowConnectionError(strError)
					End If
				End If
			Else
				Job.Release
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
		Log("[B4XPageUser] LoginUser: " & LastException.Message)
		ShowToastMessage("Failed to retrieve data", False)
	End Try
End Sub

Sub UpdateProfile
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XPageUser] UpdateProfile")
		Log("API Key=" & Main.gUserAPIKey)
		Log("Token=" & Main.gUserToken)
		Dim Map2 As Map
		Map2.Initialize
		Map2.Put("key", Main.gUserAPIKey)
		Map2.Put("token", Main.gUserToken)
		Map2.Put("user_name", txtUserName.Text.Trim)
		Map2.Put("user_location", txtUserLocation.Text.Trim)
		jsn = Utility.Map2Json(Map2)
		job.Initialize("", Me)
		job.PostString(Main.strURL & "user/update", jsn)
		Wait For (job) JobDone(job As HttpJob)
		Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			job.Release
			Log(strData)
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				Dim List1 As List
				Dim Map1 As Map
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If -1 = Map1.Get("result") Then
					If Map1.Get("message") = "Error-No-Result" Then
						ShowToastMessage("Error: Profile not found", False)
					Else If Map1.Get("message") = "Error-No-Value" Then
						ShowToastMessage("Error: Invalid Parameters", False)
					Else
						ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
					End If
					Return
				End If
				ShowMsgBox("Profile is updated!", "S U C C E S S")						
				Main.gUserName = txtUserName.Text.Trim
				Main.gUserLocation = txtUserLocation.Text.Trim
				lblUserName.Text = Main.gUserName
				lblUserLocation.Text = Main.gUserLocation
				BtnSubmit.Text = "Edit Profile"
				btnCancel.Visible = False
				txtUserName.mBase.Visible = False
				txtUserName.TextField.Visible = False
				txtUserLocation.mBase.Visible = False
				txtUserLocation.TextField.Visible = False
				lblUserName.Visible = True
				lblUserLocation.Visible = True
			Else
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
		Log("[B4XPageUser] UpdateProfile: " & LastException.Message)
		ShowToastMessage("Failed to update profile", False)
	End Try
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ShowPageAndRemovePreviousPages("MainPage")
End Sub
#Else
Sub lblBack_Click
	B4XPages.ClosePage(Me)
	B4XPages.ShowPage("MainPage")
End Sub
#End If

Sub BtnSubmit_Click
	'IME.HideKeyboard
	Select Case strMode
		Case "Login"
			If txtUserEmail.Text.Trim = "" Then
				ShowMsgBox("Please enter your Email", "E R R O R")
				Return
			End If
			If Utility.ValidateEmail(txtUserEmail.Text.Trim) = False Then
				ShowMsgBox("Email format is incorrect", "E R R O R")
				Return
			End If
			If txtPassword.Text.Trim = "" Then
				ShowMsgBox("Please enter your Password", "E R R O R")
				Return
			End If
			LoginUser
			Return
		Case "Register"
			If txtUserName.Text.Trim = "" Then
				ShowMsgBox("Please enter your Name", "E R R O R")
				Return
			End If
			If txtUserEmail.Text.Trim = "" Then
				ShowMsgBox("Please enter your Email", "E R R O R")
				Return
			End If
			If Utility.ValidateEmail(txtUserEmail.Text.Trim) = False Then
				ShowMsgBox("Email format is incorrect", "E R R O R")
				Return
			End If
			If txtPassword1.Text.Trim = "" Then
				ShowMsgBox("Please enter your Password", "E R R O R")
				Return
			End If
			If txtPassword2.Text.Trim = "" Then
				ShowMsgBox("Please repeat your Password", "E R R O R")
				Return
			End If
			If txtPassword1.Text.Trim <> txtPassword2.Text.Trim Then
				ShowMsgBox("Password not match", "E R R O R")
				Return
			End If
			#If B4J
			Dim sf As Object = xui.Msgbox2Async("Are you sure to register?", "C O N F I R M", "Y E S", "", "N O", Null)
			Wait For (sf) Msgbox_Result (Result As Int)
			If Result = xui.DialogResponse_Positive Then
				RegisterUser
			End If
			#Else If B4i
			Msgbox2("Msg", "Are you sure to register?", "C O N F I R M", Array ("Y E S", "N O"))
			Wait For Msg_Click (ButtonText As String)
			If ButtonText = "Y E S" Then
				RegisterUser
			End If
			#Else
			Msgbox2Async("Are you sure to register?", "C O N F I R M", "Y E S", "", "N O", Null, True)
			Wait For Msgbox_Result (Result As Int)
			If Result = DialogResponse.POSITIVE Then
				RegisterUser
			End If
			#End If
			Return
		Case "About"
			If BtnSubmit.Text = "Edit Profile" Then
				BtnSubmit.Text = "Update Profile"
				btnCancel.Visible = True
				txtUserName.Text = lblUserName.Text
				txtUserLocation.Text = lblUserLocation.Text
				lblUserName.Visible = False
				lblUserLocation.Visible = False
				txtUserName.mBase.Visible = True
				txtUserName.TextField.Visible = True
				txtUserLocation.mBase.Visible = True
				txtUserLocation.TextField.Visible = True
			Else
				If txtUserName.Text.Trim = "" Then
					#If B4J
					xui.MsgboxAsync("Please enter your Name", "E R R O R")
					#Else If B4i
					
					#Else
					MsgboxAsync("Please enter your Name", "E R R O R")
					#End If					
					Return
				End If
				If txtUserLocation.Text.Trim = "" Then
					#If B4J
					xui.MsgboxAsync("Please enter your Location", "E R R O R")
					#Else If B4i
					
					#Else
					MsgboxAsync("Please enter your Location", "E R R O R")
					#End If										
					Return
				End If
				UpdateProfile
			End If
	End Select
End Sub

Sub btnCancel_Click
	'Main.gUserName = txtUserName.Text.Trim
	'Main.gUserLocation = txtUserLocation.Text.Trim
	lblUserName.Text = Main.gUserName
	lblUserLocation.Text = Main.gUserLocation
	BtnSubmit.Text = "Edit Profile"
	btnCancel.Visible = False
	txtUserName.mBase.Visible = False
	txtUserName.TextField.Visible = False
	txtUserLocation.mBase.Visible = False
	txtUserLocation.TextField.Visible = False
	lblUserName.Visible = True
	lblUserLocation.Visible = True
End Sub

Sub btnReset_Click
	'If PagePassword.IsInitialized = False Then PagePassword.Initialize
	'B4XPages.AddPage("PasswordReset", PagePassword)
	'PagePassword.strMode = "Reset Password"
	B4XPages.MainPage.PagePassword.strMode = "Reset Password"
	#If B4J
		B4XPages.ShowPageAndRemovePreviousPages("PasswordReset")
	#Else
		B4XPages.ShowPage("PasswordReset")
	#End If
End Sub

Sub txtUserEmail_TextChanged (Old As String, New As String)
	BtnSubmit.Enabled = New.Length > 0
	If strMode = "Login" Then
		BtnReset.Enabled = New.Length > 0
	End If
End Sub

Sub txtUserEmail_EnterPressed
	If strMode = "Login" Then
		txtPassword.RequestFocusAndShowKeyboard
	End If	
End Sub

Sub txtPassword_EnterPressed
	'If BtnLogin.Enabled Then BtnLogin_Click
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