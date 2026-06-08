#ifdef PIXEL

#ifdef DEFAULT_FRAG

vec4 frag( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
    return color * Texel(tex, texture_coords);
}

#endif

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
    vec4 fragcolor = frag(color, tex, texture_coords, screen_coords);
    if (!isWireframeEnabled && fragcolor.a <= alphaThreshold) {
        discard;
    }
    fragcolor.a = 1.0;
    // test stuff please remove/comment-out
    // fragcolor.a = fragcolor.a * min(1, 256 * (1.0-screenPosition.z));
    // fragcolor.a = fragcolor.a * min(1, 256 * (screenPosition.z+1));
    // end test stuff
    return fragcolor;
}

#endif
