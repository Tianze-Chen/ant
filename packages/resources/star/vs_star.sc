$input a_position, a_normal, a_texcoord0
$output v_posWS, v_normalWS, v_pos, v_texcoord0

#include "common.sh"

void main()
{
    v_pos = vec4(a_position, 1.0);
    v_normalWS = normalize(mul(u_model[0], vec4(a_normal, 0.0)));
    v_posWS = mul(u_model[0], v_pos);

    gl_Position = mul(u_viewProj, v_posWS);
    v_texcoord0 = a_texcoord0;
}