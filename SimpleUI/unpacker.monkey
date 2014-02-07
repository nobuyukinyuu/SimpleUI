'The unpacker requires access to all the common widgets.  Therefore, if you don't want to import all widgets'
'namespaces to your project, you don't need to include unpacker if you don't use it.  -nobu (6 Feb 2014)
Import common
Import widgetManager
Import panel
Import Scrollers
Import textbox

'Summary:  Singleton class providing a way to easily unpack widgets from a JSON file to a WidgetManager.
Class Unpacker
	Global ValidTypes:StringMap<Widget>
	Global defaultType:String = "widget"
	
	'Summary:  Initializes the ValidTypes map with the built-in widgets.
	Function Init:Void()
		ValidTypes = New StringMap<Widget>
		
		ValidTypes.Add("widget", New Widget())
		ValidTypes.Add("pushbutton", New PushButton())
'		ValidTypes.Add("panel", New ScrollablePanel())
'		ValidTypes.Add("scroller"), New Scroller())
'		ValidTypes.Add("endless_scroller", New EndlessScroller())
		ValidTypes.Add("textbox", New TextBox())
	End Function
	
	'Summary:  Unpacks a series of objects in a SimpleUI Form to a WidgetManager.
	Function UnpackForm:WidgetManager(json:String, Input:InputPointer = Null)
		Try
			Local j:= New JsonObject(json)
			Local ws:JsonArray = JsonArray(j.Get("Widgets"))
			
			Local out:= New WidgetManager(Input)
			If ws = Null Then Return out

			For Local i:Int = 0 Until ws.Length()
				Local obj:= Unpack(JsonObject(ws.Get(i)))
				
				If obj <> Null Then out.Attach(obj)
			Next
			Return out
		Catch ex:JsonError
			Print "Unpacker:  Warning, data corrupt.  UnpackForm failed."
			Return New WidgetManager(Input)
		End Try
	End Function
		
	'Summary:  Returns a single unpacked widget from a JSON object.
	Function Unpack:Widget(j:JsonObject)
		If ValidTypes = Null Then Error("Unpacker not initialized")

		Local unpackType:String = j.GetString("type")
		If unpackType = "" Then
			Print("Unpacker:  '" + unpackType + "' is not part of Unpacker.ValidTypes.")
			Print("Unpacker:  Defaulting to '" + defaultType + "'...")
			unpackType = defaultType
		End If

		Local widget:= ValidTypes.Get(unpackType)
		
		If widget = Null Then
			Print("Unpacker:  Warning, unpacking widget as '" + unpackType + "' failed.")
			Return Null
		End If
		
		Return widget.Spawn(j.ToJson())
	End Function
End Class