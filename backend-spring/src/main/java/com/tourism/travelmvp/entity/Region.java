package com.tourism.travelmvp.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "regions")
public class Region extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 100)
    private String province;

    @Column(nullable = false)
    private Boolean eligibleForResidenceMatch = Boolean.TRUE;

    @Column(nullable = false, length = 255)
    private String halfPriceApplyUrl;

    @Column(nullable = false, length = 255)
    private String digitalTourCardApplyUrl;

    @Column(nullable = false)
    private Integer refundConditionAmount;

    @Column(nullable = false)
    private Integer mockBudgetRemaining;

    @Column(nullable = false, length = 30)
    private String dataSourceNote;

    @Column(nullable = false, length = 30)
    private String statusCode = "PREPARING";

    @Column(nullable = false)
    private Boolean digitalBenefitAvailable = Boolean.FALSE;

    @Column(nullable = false)
    private Integer displayOrder = 0;

    @Column(length = 500)
    private String restrictedResidenceTokens;

    @Column(length = 255)
    private String residenceRestrictionNote;

    private Double mapTopPercent;

    private Double mapLeftPercent;

    private Double mapCenterLat;

    private Double mapCenterLng;
}
