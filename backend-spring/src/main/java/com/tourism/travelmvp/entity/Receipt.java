package com.tourism.travelmvp.entity;

import com.tourism.travelmvp.enums.PaymentType;
import com.tourism.travelmvp.enums.ReceiptReviewStatus;
import com.tourism.travelmvp.enums.ReceiptUsageScope;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "receipts")
public class Receipt extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_file_id", nullable = false, unique = true)
    private UploadedFile uploadedFile;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private PaymentType paymentType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ReceiptUsageScope usageScope = ReceiptUsageScope.GENERAL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ReceiptReviewStatus reviewStatus = ReceiptReviewStatus.PENDING;

    private Integer amount;

    @Column(nullable = false)
    private Integer eligibleAmount = 0;

    @Column(length = 255)
    private String reviewReason;

    @Column(length = 500)
    private String rawText;
}
