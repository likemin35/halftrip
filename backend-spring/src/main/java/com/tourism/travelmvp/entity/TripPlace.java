package com.tourism.travelmvp.entity;

import com.tourism.travelmvp.enums.PlaceCategory;
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
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "trip_places")
public class TripPlace extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private PlaceCategory placeType;

    @Column(nullable = false)
    private Long referencePlaceId;

    @Column(nullable = false, length = 150)
    private String placeName;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(nullable = false)
    private Integer visitOrder;

    @Column
    private Double latitude;

    @Column
    private Double longitude;

    @Column(nullable = false)
    private Boolean checked = Boolean.TRUE;
}
