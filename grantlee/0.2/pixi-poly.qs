var exportModel = function(global) {
	var bodies = global.bodies;

	var exportedData = {
		generator_info: "PixiJS polygon exporter. Visit https://github.com/eXponenta for more!"
	};

	for (var i = 0; i < bodies.length; i++) {
		var body = bodies[i];
		var shapes = [];
		for (var j = 0; j < body.fixtures.length; j++) {
			var fixture = body.fixtures[j];
			var shape = exportFixtureParams(fixture);
			if (fixture.isCircle) {
				shape.circle = exportCircle(fixture);
			} else {
				if (global.decompose) {
					shape.points = exportPolygons(fixture.polygons, global.flatPoints);
				} else {
					shape.points = exportPolygons([fixture.hull], global.flatPoints);
				}
			}
			shapes.push(shape);
		}

		if (body.concatFixtures) {
			shapes = concatFixtures(shapes);
		}

		if (global.useBody) {
			exportedData[body.name] = {
				label: body.label ? body.label : body.name,
				shapes: shapes
			};
		} else {
			if (!exportedData.shapes) {
				exportedData.shapes = [];
			}
			exportedData.shapes = exportedData.shapes.concat(shapes);
		}
	}

	return JSON.stringify(exportedData, null, global.prettyPrint ? "\t" : undefined);
};

var concatFixtures = function(fixtures) {
	var output = [];

	for (var i = 0; i < fixtures.length; i++) {
		var fixtureA = fixtures[i];
		if (!fixtureA || fixtureA.type === "circle") {
			continue;
		}

		for (var j = i + 1; j < fixtures.length; j++) {
			var fixtureB = fixtures[j];
            if (!fixtureB || fixtureB.type === "circle") {
                continue;
            }
			if (
				(fixtureA.label === fixtureB.label && fixtureA.label) ||
				(!fixtureA.label && fixtureA.id === fixtureB.id)
			) {
				fixtureA.points = fixtureA.points.concat(fixtureB.points);
				fixtures[j] = undefined;
			}
		}

		output.push(fixtureA);
	}

	return output;
};

var exportFixtureParams = function(fixture) {
	var result = {
		label: fixture.label,
		id: fixture.id,
		type: fixture.isCircle ? "circle" : "polygon"
	};
	return result;
};

var exportCircle = function(circle) {
	var result = {
		x: circle.center.x,
		y: circle.center.y,
		radius: circle.radius
	};
	return result;
};

var exportPolygons = function(polygons, flatArray) {
	var result = [];
	for (var i = 0; i < polygons.length; i++) {
		var resultPoly = [];
		for (var j = 0; j < polygons[i].length; j++) {
			if (flatArray) {
				resultPoly.push(polygons[i][j].x, polygons[i][j].y);
			} else {
				resultPoly.push([polygons[i][j].x, polygons[i][j].y]);
			}
		}
		result.push(resultPoly);
	}
	return result;
};

//exports
exportModel.filterName = "exportModel";
Library.addFilter("exportModel");

var dumpAll = function(global) {
	return JSON.stringify(global, null, "\t");
};
dumpAll.filterName = "dumpAll";
Library.addFilter("dumpAll");
