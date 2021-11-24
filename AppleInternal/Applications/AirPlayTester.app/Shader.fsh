/*
	Shader.fsh
	
	Copyright 2011 Apple Inc. All rights reserved.
 */
/*
	$Log$
	9aug2011 sojakian
	<rdar://9865650> Add an OpenGL test. <mcalhoun> 
 */

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
