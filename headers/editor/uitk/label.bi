''
'' uitk label
'' by mishka
''

type uiLabel extends uiElement
	declare constructor ()
	declare sub update() override 
end type

constructor uiLabel()
	this.box.style = blank
end constructor

sub uiLabel.update()
	' does nothing and simply exists for consistency
end sub

