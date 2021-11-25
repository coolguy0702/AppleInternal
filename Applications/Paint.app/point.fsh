precision highp float;

varying lowp vec4 color;

varying float v_R;
varying float v_R2;
varying float v_tSize;

varying float pseudoRand;

uniform sampler2D tex;
uniform lowp float drawTextured;

void main()
{
    if (drawTextured > 0.5) {
        vec2 texCoord;
        if (pseudoRand < 0.25) {
            texCoord = vec2(1.0 - gl_PointCoord.s, gl_PointCoord.t);
        } else if (pseudoRand < 0.50) {
            texCoord = vec2(1.0 - gl_PointCoord.s, 1.0 - gl_PointCoord.t);
        } else if (pseudoRand < 0.75) {
            texCoord = vec2(gl_PointCoord.s, 1.0 - gl_PointCoord.t);
        } else {
            texCoord = gl_PointCoord;
        }
        gl_FragColor = color * texture2D(tex, texCoord);
        //gl_FragColor.rgb = color.rgb;
        //gl_FragColor.a = texture2D(tex, texCoord).a;
    } else {
        vec2 UV = 2.0 * (gl_PointCoord - vec2(0.5,0.5));
        float dotUV = dot(UV,UV);

        float distanceToCenterSquared = v_R - dotUV;
        bool inside = distanceToCenterSquared >= 0.0;
        float distanceToCircleBoundary = v_R2 - sqrt(dotUV);

        float alpha = clamp(distanceToCircleBoundary * v_tSize, 0.0, 1.0);
        float finalAlpha = mix(0.0, alpha, float(inside));
        gl_FragColor = color * finalAlpha;
    }
}
