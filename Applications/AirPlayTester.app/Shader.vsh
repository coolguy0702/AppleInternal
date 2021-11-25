/*
	Shader.vsh
	
	Copyright 2011 Apple Inc. All rights reserved.
 */
/*
	$Log$
	9aug2011 sojakian
	<rdar://9865650> Add an OpenGL test. <mcalhoun> 
 */

attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

uniform float translate;
uniform float translateFactor;

void main()
{
    gl_Position = position;
    gl_Position.y += sin(translate) * translateFactor;

    colorVarying = color;
}
