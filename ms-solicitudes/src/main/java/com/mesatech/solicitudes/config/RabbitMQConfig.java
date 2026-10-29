package com.mesatech.solicitudes.config;

import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// Convierte el JSON recibido al objeto del parametro del listener (el tipo se infiere del metodo,
// no del header __TypeId__ que envia el publicador). La cola y el binding se crean en RabbitMQ.
// Spring Boot 3.x usa Jackson2JsonMessageConverter (en Boot 4 / Jackson 3 el equivalente
// es JacksonJsonMessageConverter, el que muestra la guia del laboratorio).
@Configuration
public class RabbitMQConfig {

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
