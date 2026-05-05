package com.tourism.travelmvp.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "lodging_infos")
public class LodgingInfo extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_file_id")
    private UploadedFile uploadedFile;

    @Column(length = 150)
    private String lodgingName;

    @Column(length = 100)
    private String representativeName;

    @Column(length = 40)
    private String phoneNumber;

    @Column(length = 255)
    private String address;

    @Column(columnDefinition = "TEXT")
    private String signatureSvgPath;

    @Column(nullable = false)
    private Boolean agreedPersonalInfo = Boolean.FALSE;

    @Column(nullable = false)
    private Boolean agreedStayProof = Boolean.FALSE;
}

