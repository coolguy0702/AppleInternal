attribute vec4 position;
attribute vec4 vertexColor;
attribute float pointSize;

uniform mat4 MVP;
uniform lowp float drawTextured;

varying lowp vec4 color;

varying float v_R;
varying float v_R2;
varying float v_tSize;

varying float pseudoRand;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    gl_Position = MVP * position;

    float paddedPointSize = pointSize + 1.5;
    float invPaddedPointSize = 1.0/paddedPointSize;

    if (drawTextured < 0.5) {
        gl_PointSize =  paddedPointSize;
        float radiusTextureSpace = 0.5 * (pointSize / paddedPointSize) + invPaddedPointSize * 0.5;
        v_R = 2.0 * radiusTextureSpace;
        v_R2 =  4.0 * radiusTextureSpace * radiusTextureSpace;
        v_tSize = pointSize * 0.5;
        pseudoRand = rand(position.xy);
    } else {
        gl_PointSize = pointSize;
    }

    color = vertexColor;
}