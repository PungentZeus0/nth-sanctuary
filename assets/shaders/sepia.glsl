
extern number intensity; // 0.0 = original, 1.0 = full sepia
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords) * color;

	// Standard grayscale luminance calculation
	float gray = dot(pixel.rgb, vec3(0.3, 0.59, 0.11));

	// Sepia tone conversion
	vec3 sepia = vec3(
		gray * 1.2,   // Red
		gray * 1.0,   // Green
		gray * 0.8    // Blue
	);

	// Mix original color with sepia tone based on intensity
	vec3 finalColor = mix(pixel.rgb, sepia, intensity);

	return vec4(finalColor, pixel.a);
}