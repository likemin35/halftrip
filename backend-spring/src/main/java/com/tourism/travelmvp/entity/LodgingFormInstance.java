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
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "lodging_form_instances")
public class LodgingFormInstance extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id", nullable = false, unique = true)
    private Trip trip;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id", nullable = false)
    private LodgingFormTemplate template;

    @Column(nullable = false, columnDefinition = "LONGTEXT")
    private String templateSnapshotJson;

    @Column(nullable = false, columnDefinition = "LONGTEXT")
    private String payloadJson;

    @Column(nullable = false, length = 40)
    private String status = "DRAFT";

    @Column(length = 255)
    private String renderedPdfFileName;

    private LocalDateTime lastRenderedAt;
}
