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
		
	Method New(input:InputPointer)
		Self.Input = input
	End Method
	
	Method New(widgets:Stack<Widget>, input:InputPointer = Null)
		Self.Input = input
		Self.Widgets = widgets		
	End Method

	'Summary:  Attaches a widget to this manager for control.  Overrides the widget's input if specified.
	Method Attach:Int(widget:Widget, id:Int = -1, overrideInput:Bool = True)
		If overrideInput And (Input <> Null) Then widget.Input = Input

		'To generate a unique ID, we must find a number that's unlikely to be repeated no matter how many widgets we add here.
		'Doing this in int32 space is difficult, so we comprimise by attempting to fill most of the values in the upper limit
		'of this space.  14 bits of data (not counting the sign bit) are allocated high and assigned to a random number, then
		'masked against the current stack size.  This should provide unique values for at least 100,000 widgets, while giving
		'only a 1-in-16382 chance of an auto ID collision if the stack size shrinks and stack length is repeated again.

		'All negative numbers (except for -1), and numbers from 0-$1FFFF are all valid ID's that can be manually assigned
		'with no chance of a collision by the auto-assignment.
				
		If id = -1 Then id = (Rnd(1, $3FFF) Shl 17) | Widgets.Length() 'Auto-assign a unique widget ID. Should support >100k widgets.
		
		Widgets.Push(widget)
		WidgetsByID.Add(id, widget)
		
		Return id
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
		WidgetsByID.Remove(id)
		Widgets.RemoveEach(w)
	End Method
	
	Method Remove:Bool(p:Widget)
		For Local o:Widget = EachIn WidgetsByID.Values
			If o = p Then
				WidgetsByID.Remove(o)
				Return True
			End If
		Next
		
		Return False
	End Method
End Class