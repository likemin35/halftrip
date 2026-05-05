package com.tourism.travelmvp.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "lodging_form_templates")
public class LodgingFormTemplate extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id", nullable = false)
    private Region region;

    @Column(nullable = false, length = 80, unique = true)
    private String templateKey;

    @Column(nullable = false, length = 150)
    private String templateName;

    @Column(nullable = false, length = 40)
    private String sourceFormat;

    @Column(length = 255)
    private String sourceFilePath;

    @Column(length = 255)
    private String renderAssetPath;

    @Column(nullable = false, length = 120)
    private String previewTitle;

    @Column(length = 255)
    private String previewSubtitle;

    @Column(nullable = false, columnDefinition = "LONGTEXT")
    private String templateSchemaJson;

    @Column(nullable = false, length = 40)
    private String dataSourceNote;

    @Column(nullable = false)
    private Boolean isActive = Boolean.TRUE;
}
