package com.tourism.travelmvp.entity;

import com.tourism.travelmvp.enums.AuthProvider;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "users")
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(length = 80, unique = true)
    private String loginId;

    @Column(nullable = false, unique = true, length = 160)
    private String email;

    @Column(length = 255)
    private String passwordHash;

    @Column(length = 40)
    private String phoneNumber;

    @Column(length = 120)
    private String residence;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AuthProvider authProvider;

    @Column(length = 120)
    private String oauthSubject;
}
