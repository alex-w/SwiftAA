//
//  Planets.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 03/07/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation

// To be understood as a "non-Earth" planet
public class Planet: Object, CelestialBody, PlanetaryBase, PlanetaryPhenomena, ElementsOfPlanetaryOrbit, EllipticalPlanetaryDetails, IlluminatedFraction  {

    public class var averageColor: Color {
        get { return Color.white }
    }
        
    public lazy var planetaryDetails: KPCAAEllipticalPlanetaryDetails = {
        [unowned self] in
        return KPCAAElliptical_CalculatePlanetaryDetails(self.julianDay.value, self.planetaryObject, self.highPrecision)
        }()
    
    public lazy var ellipticalObjectDetails: KPCAAEllipticalObjectDetails = {
        [unowned self] in
        return KPCAAElliptical_CalculateObjectDetailsNoElements(self.julianDay.value, self.highPrecision)
        }()
    
    public var equatorialCoordinates: EquatorialCoordinates {
        get { return self.eclipticCoordinates.toEquatorialCoordinates() }
    }
    
    public var eclipticCoordinates: EclipticCoordinates {
        get {
            // To compute the _apparent_ RA and Dec from Ecl. coords, the true obliquity must be used (hence mean: false)
            let epsilon = obliquityOfEcliptic(julianDay: self.julianDay, mean: false)
            let longitude = KPCAAEclipticalElement_EclipticLongitude(self.julianDay.value, self.planet, self.highPrecision)
            let latitude = KPCAAEclipticalElement_EclipticLatitude(self.julianDay.value, self.planet, self.highPrecision)
            return EclipticCoordinates(lambda: Degree(longitude), beta: Degree(latitude), epsilon: epsilon)
        }
    }

    public var radiusVector: AU {
        get { return KPCAAEclipticalElement_RadiusVector(self.julianDay.value, self.planet, self.highPrecision) }
    }
    
    public var equatorialSemiDiameter: Degree {
        get { return Degree(KPCAADiameters_EquatorialSemiDiameterB(self.planet, self.radiusVector)) }
    }
    
    public var polarSemiDiameter: Degree {
        get { return Degree(KPCAADiameters_PolarSemiDiameterB(self.planet, self.radiusVector)) }
    }
}

// special Pluto:
public class DwarfPlanet: Object, PlanetaryBase {}


