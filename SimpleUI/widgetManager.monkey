'This class is somewhat like a server, which allows you to attach UI widgets to it.  The convenience of this class
'comes from the fact that most UI objects inherit Widget and can therefore be polled and rendered by the manager.
'In the future, this class may allow dispatch groups to make it easier to make the behavior of one group of widgets
'dependant on another action, such as another widget's state or a different InputPointer, but as of this writing, 
'there only exists the ability to render/poll all widgets inside a WidgetManager at once.
'								-Nobuyuki (nobu@subsoap.com) 19 August 2013 

Import InputPointers
Import ui
Import widget

Class WidgetManager
	Field Enabled:Bool = True 'DIFFERENT than Widget's Enabled property! Setting this True stops the manager from polling or rendering anything.
	Field Input:InputPointer
	Field Widgets:= New Stack<Widget>
	Field WidgetsByID:= New IntMap<Widget>  'For accessing widgets by ID
	Field WidgetsByName:= New StringMap<Widget>
		
	Method New(input:InputPointer)
		Self.Input = input
	End Method
	
'	Method New(widgets:Stack<Widget>, input:InputPointer = Null)
'		Self.Input = input
'		Self.Widgets = widgets		
'	End Method
	
	Method New(widgets:Widget[], input:InputPointer = Null)
		Self.Input = input
		
		For Local i:Int = 0 Until widgets.Length
			Attach(widgets[i])
		Next
	End Method	

	'Summary:  Attaches a widget to this manager for control.  Overrides the widget's input if specified.
	Method Attach:Int(widget:Widget, id:Int = -1, overrideInput:Bool = True)
		If overrideInput And (Input <> Null) Then widget.Input = Input

		If id = -1 Then id = widget.id  'Set ID to whatever the widget's ID is.
		If id = -1 Then                 'If the widget doesn't have an ID, make one.
			id = UI.GenerateID(Widgets.Length())
			widget.id = id
		End If
						
		Widgets.Push(widget)
		WidgetsByID.Add(id, widget)
		If widget.name <> "" Then
			Local ok:Bool = WidgetsByName.Add(widget.name, widget)
			If Not ok Then
				Print("WidgetManager:  Warning, widget '" + widget.name + "' already exists.")
				Print("WidgetManager:  The previous reference has been overwritten.")
			End If
		End If
		
		Return id
	End Method
	
	Method DetachAll:Void()
		WidgetsByName.Clear()
		WidgetsByID.Clear()
		Widgets.Clear()
	End Method
	
	
	'Summary:  Polls all widgets attached to this manager.
	Method PollAll:Void(xOffset:Float = 0, yOffset:Float = 0)
		If Enabled = False Then Return

		For Local o:Widget = EachIn Widgets
			o.Poll(xOffset, yOffset)
		Next
	End Method
	
	'Summary:  Renders all widgets attached to this manager.
	Method RenderAll:Void(xOffset:Float = 0, yOffset:Float = 0)
		If Enabled = False Then Return
	
		For Local o:Widget = EachIn Widgets
			o.Render(xOffset, yOffset)
		Next
	End Method
	
	Method Remove:Void(id:Int)
		Local w:Widget = WidgetsByID.Get(id)
		If w <> Null
			WidgetsByID.Remove(id)
			Widgets.RemoveEach(w)
			WidgetsByName.Remove(w.name)
		Else
			Print("WidgetManager:  Warning, widget " + id + " not found.")
		End If
	End Method
	
	Method Remove:Void(p:Widget)
		WidgetsByID.Remove(p.id)
		Widgets.RemoveEach(p)
		WidgetsByName.Remove(p.name)
	End Method
	
	Method Remove:Void(name:String)
		Local w:Widget = WidgetsByName.Get(name)
		If w <> Null
			WidgetsByName.Remove(name)
			WidgetsByID.Remove(w.id)
			Widgets.RemoveEach(w)
		Else
			Print("WidgetManager:  Warning, widget '" + name + "' not found.")
		
		End If
	End Method
	
	Method RemoveAll:Void()
		Widgets.Clear()
		WidgetsByID.Clear()
		WidgetsByName.Clear()
	End Method	
End Class