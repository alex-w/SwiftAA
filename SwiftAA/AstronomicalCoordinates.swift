//
//  Coordinates.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/07/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation

public struct EquatorialCoordinates {
    fileprivate(set) var rightAscension: Hour
    fileprivate(set) var declination: Degree
    public let epoch: Double
    
    var alpha: Hour {
        get { return self.rightAscension }
        set { self.rightAscension = newValue }
    }
    
    var delta: Degree {
        get { return self.declination }
        set { self.declination = newValue }
    }
    
    init(alpha: Hour, delta: Degree, epsilon: Double) {
        self.rightAscension = alpha
        self.declination = delta
        self.epoch = epsilon
    }
    
    func toEclipticCoordinates() -> EclipticCoordinates {
        let components = KPCAACoordinateTransformation_Equatorial2Ecliptic(self.rightAscension, self.declination.value, self.epoch)
        return EclipticCoordinates(lambda: Degree(components.X), beta: Degree(components.Y), epsilon: self.epoch)
    }
    
    /**
     Transform the coordinates to galactic ones.
     
     The galactic coordinates system has been defined by the International Astronomical Union 
     in 1959. In the standard equatorial system of B1950.0, the galactic North Pole
     has the coordinates: alpha = 192.25 Degree, and delta = 27.4 Degree, and the origin
     of the galactic longitude is the point (in western Sagittarius) of the galactic equator 
     which is 33º distant from the ascending node (in western Aquila) of the galactic equator
     with the equator of B1950.0.
     These values have been fixed conventionally and therefore must be considered as exact for 
     the mentionned equinox of B1950.0
     
     - returns: The corresponding galactic coordinates.
     */
    func toGalacticCoordinates() -> GalacticCoordinates {
        let precessedCoords = self.precessedCoordinates(to: StandardEpoch_B1950_0)
        let components = KPCAACoordinateTransformation_Equatorial2Galactic(precessedCoords.rightAscension, precessedCoords.declination.value)
        return GalacticCoordinates(l: Degree(components.X), b: Degree(components.Y))
    }
    
    func toHorizontalCoordinates(forGeographicalCoordinates coords: GeographicCoordinates, julianDay: JulianDay) -> HorizontalCoordinates {
        let lha = julianDay.meanLocalSiderealTime(forGeographicLongitude: coords.longitude.value)
        let components = KPCAACoordinateTransformation_Equatorial2Horizontal(lha, self.declination.value, coords.latitude.value)
        return HorizontalCoordinates(azimuth: Degree(components.X),
                                     altitude: Degree(components.Y),
                                     geographicCoordinates: coords,
                                     julianDay: julianDay,
                                     epoch: self.epoch)
    }
    
    func precessedCoordinates(to newEpoch: Double) -> EquatorialCoordinates {
        let components = KPCAAPrecession_PrecessEquatorial(self.rightAscension, self.declination.value, self.epoch, newEpoch)
        return EquatorialCoordinates(alpha: components.X, delta: Degree(components.Y), epsilon: newEpoch)
    }
    
    func angularSeparation(from otherCoordinates: EquatorialCoordinates) -> Degree {
        return Degree(KPCAAAngularSeparation_Separation(self.alpha, self.delta.value, otherCoordinates.alpha, otherCoordinates.delta.value))
    }
    
    func positionAngle(with otherCoordinates: EquatorialCoordinates) -> Degree {
        return Degree(KPCAAAngularSeparation_PositionAngle(self.alpha, self.delta.value, otherCoordinates.alpha, otherCoordinates.delta.value))
    }
}

public struct EclipticCoordinates {
    fileprivate(set) var celestialLongitude: Degree
    fileprivate(set) var celestialLatitude: Degree
    public let epoch: Double
    
    var lambda: Degree {
        get { return self.celestialLongitude }
        set { self.celestialLongitude = newValue }
    }
    
    var beta: Degree {
        get { return self.celestialLatitude }
        set { self.celestialLatitude = newValue }
    }
    
    var epsilon: Double {
        get { return self.epoch }
    }
    
    init(lambda: Degree, beta: Degree, epsilon: Double) {
        self.celestialLongitude = lambda
        self.celestialLatitude = beta
        self.epoch = epsilon
    }
    
    func toEquatorialCoordinates() -> EquatorialCoordinates {
        let components = KPCAACoordinateTransformation_Ecliptic2Equatorial(self.celestialLongitude.value, self.celestialLatitude.value, self.epoch)
        return EquatorialCoordinates(alpha: components.X, delta: Degree(components.Y), epsilon: self.epoch)
    }
    
    func precessedCoordinates(to newEpoch: Double) -> EclipticCoordinates {
        let components = KPCAAPrecession_PrecessEcliptic(self.celestialLongitude.value, self.celestialLatitude.value, self.epoch, newEpoch)
        return EclipticCoordinates(lambda: Degree(components.X), beta: Degree(components.Y), epsilon: newEpoch)
    }
}

public struct GalacticCoordinates {
    fileprivate(set) var galacticLongitude: Degree
    fileprivate(set) var galacticLatitude: Degree
    public let epoch: Double = StandardEpoch_B1950_0

    var l: Degree {
        get { return self.galacticLongitude }
        set { self.galacticLongitude = newValue }
    }
    
    var b: Degree {
        get { return self.galacticLatitude }
        set { self.galacticLatitude = newValue }
    }

    init(l: Degree, b: Degree) {
        self.galacticLongitude = l
        self.galacticLatitude = b
    }
    
    /**
     Transform the coordinates to equatorial ones.
     Careful: the epoch is necessarily that of the galactic coordinates which is always B1950.0.
     
     - returns: The corresponding equatorial coordinates.
     */
    func toEquatorialCoordinates() -> EquatorialCoordinates {
        let components = KPCAACoordinateTransformation_Galactic2Equatorial(self.galacticLongitude.value, self.galacticLatitude.value)
        return EquatorialCoordinates(alpha: components.X, delta: Degree(components.Y), epsilon: self.epoch)
    }
}

public struct HorizontalCoordinates {
    fileprivate(set) var azimuth: Degree // westward from the South see AA. p91
    fileprivate(set) var altitude: Degree
    fileprivate(set) var geographicCoordinates: GeographicCoordinates
    fileprivate(set) var julianDay: JulianDay
    fileprivate(set) var epoch: Double
    
    init(azimuth: Degree, altitude: Degree, geographicCoordinates: GeographicCoordinates, julianDay: JulianDay, epoch: Double) {
        self.azimuth = azimuth
        self.altitude = altitude
        self.geographicCoordinates = geographicCoordinates
        self.julianDay = julianDay
        self.epoch = epoch
    }
    
    func toEquatorialCoordinates() -> EquatorialCoordinates {
        let components = KPCAACoordinateTransformation_Horizontal2Equatorial(self.azimuth.value, self.altitude.value, self.geographicCoordinates.latitude.value)
        return EquatorialCoordinates(alpha: components.X, delta: Degree(components.Y), epsilon: self.epoch)
    }

}

