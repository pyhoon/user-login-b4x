B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.2
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
	Private xui As XUI 'ignore
	Private KVS As KeyValueStore
	Dim strMode As String
	Private txtUserEmail As B4XFloatTextField
	Private txtOldPassword As B4XFloatTextField
	Private txtUserPassword1 As B4XFloatTextField
	Private txtUserPassword2 As B4XFloatTextField	
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
End Sub

Private Sub B4XPage_Appear
	SelectMode
End Sub

Sub SelectMode
	Select Case strMode
		Case "Change Password"
			Root.RemoveAllViews
			Root.LoadLayout("PasswordChange")
			'IME.SetLengthFilter(txtOldPassword, 20)
			'IME.SetLengthFilter(txtPassword1, 20)
			'IME.SetLengthFilter(txtPassword2, 20)
		Case "Reset Password"
			Root.RemoveAllViews
			Root.LoadLayout("PasswordReset")
	End Select
End Sub
'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.

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

Sub btnSubmit_Click
	Select Case strMode
		Case "Change Password"
			If txtOldPassword.Text.Trim = "" Then
				ShowMsgBox("Please enter your Current Password", "E R R O R")
				Return
			End If
			If txtUserPassword1.Text.Trim = "" Then
				ShowMsgBox("Please enter your New Password", "E R R O R")
				Return
			End If
			If txtUserPassword2.Text.Trim = "" Then
				ShowMsgBox("Please confirm your Password", "E R R O R")
				Return
			End If
			If txtUserPassword1.Text.Trim <> txtUserPassword2.Text.Trim Then
				ShowMsgBox("Password not match", "E R R O R")
				Return
			End If
			#If B4J
			Dim sf As Object = xui.Msgbox2Async("Are you sure to change password?", "C O N F I R M", "Y E S", "", "N O", Null)
			Wait For (sf) Msgbox_Result (Result As Int)
			If Result = xui.DialogResponse_Positive Then
				ChangePassword(txtOldPassword.Text.Trim, txtUserPassword1.Text.Trim)
			End If
			#Else If B4i
			Msgbox2("Msg", "Are you sure to change password?", "C O N F I R M", Array ("Y E S", "N O"))
			Wait For Msg_Click (ButtonText As String)
			If ButtonText = "Y E S" Then
				ChangePassword(txtOldPassword.Text.Trim, txtUserPassword1.Text.Trim)
			End If
			#Else
			Msgbox2Async("Are you sure to change password?", "C O N F I R M", "Y E S", "", "N O", Null, True)
			Wait For Msgbox_Result (Result As Int)
			If Result = DialogResponse.POSITIVE Then
				ChangePassword(txtOldPassword.Text.Trim, txtUserPassword1.Text.Trim)
			End If
			#End If
			Return
		Case "Reset Password"
			If txtUserEmail.Text.Trim = "" Then
				ShowMsgBox("Please enter your Email", "E R R O R")
				Return
			End If
			If Utility.ValidateEmail(txtUserEmail.Text.Trim) = False Then
				ShowMsgBox("Email format is incorrect", "E R R O R")
				Return
			End If
			#If B4J
			Dim sf As Object = xui.Msgbox2Async("Are you sure to reset password?", "C O N F I R M", "Y E S", "", "N O", Null)
			Wait For (sf) Msgbox_Result (Result As Int)
			If Result = xui.DialogResponse_Positive Then
				ResetPassword(txtUserEmail.Text.Trim)
			End If
			#Else If B4i
			Msgbox2("Msg", "Are you sure to reset password?", "C O N F I R M", Array ("Y E S", "N O"))
			Wait For Msg_Click (ButtonText As String)
			If ButtonText = "Y E S" Then
				ResetPassword(txtUserEmail.Text.Trim)
			End If
			#Else
			Msgbox2Async("Are you sure to reset password?", "C O N F I R M", "Y E S", "", "N O", Null, True)
			Wait For Msgbox_Result (Result As Int)
			If Result = DialogResponse.POSITIVE Then
				ResetPassword(txtUserEmail.Text.Trim)
			End If
			#End If
			Return
	End Select
End Sub

Sub ChangePassword(strOldPassword As String, strNewPassword As String)
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XPagePassword] ChangePassword")
		Utility.ShowProgressDialog("Connecting to server...")
		job.Initialize("", Me)
		job.Download(Main.strURL & "user/connect")
		Wait For (job) JobDone(job As HttpJob)
		Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			'Log(strData)
			job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Calling API...")
					Dim Map2 As Map
					Map2.Initialize
					Map2.Put("eml", Main.gUserEmail)
					Map2.Put("old", strOldPassword)
					Map2.Put("new", strNewPassword)
					jsn = Utility.Map2Json(Map2)
					job.Initialize("", Me)
					job.PostString(Main.strURL & "password/change", jsn)
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
									ShowToastMessage("Error: Invalid Password", False)
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else If Map1.Get("message") = "Error-Same-Value" Then
									ShowToastMessage("Error: Password cannot be same", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If Map1.Get("message") = "success" Then
								ShowToastMessage("Password changed successfully!", False)
								' Try to relogin
								Main.gLogin = 0
								Main.gUserAPIKey = ""
								Main.gUserToken = ""
								' Delete Token
								KVS.DeleteAll
								Sleep(0)
							End If
							B4XPages.ShowPageAndRemovePreviousPages("MainPage")
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
		Log("[B4XPagePassword] ChangePassword: " & LastException.Message)
		ShowToastMessage("Failed to change password", False)
	End Try
End Sub

Sub ResetPassword(strUserEmail As String)
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim List1 As List
	Dim Map1 As Map
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XPagePassword] ResetPassword")
		Utility.ShowProgressDialog("Connecting to server...")
		job.Initialize("", Me)
		job.Download(Main.strURL & "user/connect")
		Wait For (job) JobDone(job As HttpJob)
		Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			'Log(strData)
			job.Release
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If 1 = Map1.Get("Connected") Then
					Utility.ShowProgressDialog("Calling API...")
					Dim Map2 As Map
					Map2.Initialize
					Map2.Put("eml", strUserEmail)
					jsn = Utility.Map2Json(Map2)
					job.Initialize("", Me)
					job.PostString(Main.strURL & "password/reset", jsn)
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
									ShowToastMessage("Error: Invalid Email", False)
								Else If Map1.Get("message") = "Error-No-Value" Then
									ShowToastMessage("Error: Invalid Parameters", False)
								Else
									ShowToastMessage("Error: Uncaught error" & CRLF & Map1.Get("message"), False)
								End If
								Return
							End If
							If Map1.Get("message") = "success" Then
								ShowToastMessage("Password reset has been requested successfully!", False)
							End If
							'Activity.Finish							
							#If B4J
							B4XPages.ShowPageAndRemovePreviousPages("MainPage")
							#Else
							B4XPages.ClosePage(Me)
							#End If
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
		Log("[B4XPagePassword] ResetPassword: " & LastException.Message)
		ShowToastMessage("Failed to reset password", False)
	End Try
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