package com.mesatech.bff;

import com.mesatech.bff.config.ProdSecurityConfig;
import com.mesatech.bff.controller.CatalogoProxyController;
import com.mesatech.bff.exception.GlobalExceptionHandler;
import com.mesatech.bff.service.ProxyService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Con el perfil prod, un usuario sin el rol requerido debe recibir 403 (no 500 ni 404)
@WebMvcTest(CatalogoProxyController.class)
@Import({ProdSecurityConfig.class, GlobalExceptionHandler.class})
@ActiveProfiles("prod")
@TestPropertySource(properties = {
        "services.catalogo.url=http://catalogo.test",
        "ENTRA_ISSUER_URI=https://issuer.test/v2.0",
        "ENTRA_AUDIENCE=audience-test"
})
class PermisosPorRolTest {

    @Autowired
    private MockMvc mvc;

    @MockBean
    private ProxyService proxyService;

    @MockBean
    private JwtDecoder jwtDecoder;

    private static final String CUERPO = "{\"nombre\":\"X\",\"activo\":true}";

    @Test
    void clienteNoPuedeCrearCategoria() throws Exception {
        mvc.perform(post("/v1/catalogo/categorias")
                        .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_CLIENTE")))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(CUERPO))
                .andExpect(status().isForbidden());
    }

    @Test
    void administradorSiPuedeCrearCategoria() throws Exception {
        when(proxyService.forward(any(), any(), any(), any()))
                .thenReturn(ResponseEntity.status(201).body("{}"));
        mvc.perform(post("/v1/catalogo/categorias")
                        .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMINISTRADOR")))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(CUERPO))
                .andExpect(status().isCreated());
    }

    @Test
    void sinTokenEsNoAutorizado() throws Exception {
        mvc.perform(post("/v1/catalogo/categorias")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(CUERPO))
                .andExpect(status().isUnauthorized());
    }
}
