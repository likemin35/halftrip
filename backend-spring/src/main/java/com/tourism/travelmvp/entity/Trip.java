package com.tourism.travelmvp.entity;

import com.tourism.travelmvp.enums.TripStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "trips")
public class Trip extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id", nullable = false)
    private Region region;

    @Column(nullable = false, length = 100)
    private String applicantName;

    @Column(nullable = false, length = 40)
    private String phoneNumber;

    @Column(nullable = false, length = 120)
    private String residence;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    @Column(nullable = false)
    private Integer travelerCount = 2;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private TripStatus status;

    @Column(nullable = false)
    private Integer refundConditionAmount;

    @Column(nullable = false)
    private Integer totalSpentAmount = 0;

    @Column(nullable = false)
    private Boolean settlementApplied = Boolean.FALSE;

    private LocalDateTime settlementAppliedAt;

    // Lombok annotation processing can be inconsistent in some local setups,
    // so expose the fields used by settlement calculations explicitly.
    public Integer getRefundConditionAmount() {
        return refundConditionAmount;
    }

    public Integer getTotalSpentAmount() {
        return totalSpentAmount;
    }
}
