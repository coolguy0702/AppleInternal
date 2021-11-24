uniform mat4 rotationMatrix;

vec3 frequencyToColor(float w)
{
	vec4 bandcenter = vec4(0.279, 0.5, 0.721, 0.8735);
	vec4 bandwidth = vec4(3.6, 3.6, 3.6, 8.0);
	vec4 rgbv = bandwidth*(w-bandcenter);
	vec4 result = clamp(1.0-rgbv*rgbv, 0.0, 1.0);
	vec3 color = vec3(result.r+0.35*result.a, result.g, result.b);
	return mix(color, 0.3, length(color.rgb)*0.577);
}

#pragma opaque
#pragma body

// Effect
vec3 adjustedView = (vec4(_surface.view, 0.0) * rotationMatrix).xyz;
float dp = dot(adjustedView, _surface.normal);
float frequency = smoothstep(0.5, 1.0, dp);

// Add effect to computed color
_output.color.rgb += (_surface.metalness * frequencyToColor(frequency));
