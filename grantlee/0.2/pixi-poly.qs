var exportModel = function(global) {
	var bodies = global.bodies;

	var exportedData = {
		generator_info: "PixiJS polygon exporter. Visit https://github.com/eXponenta for more!",
		tag: "pixi_polygon_points",
		format: {
			decomposed: global.decompose,
			flat: global.flatPoints,
			body: global.useBody,
			normalized: global.normalizePoints
		}
	};

	for (var i = 0; i < bodies.length; i++) {
		var body = bodies[i];
		var options = {
			source: body.size,
			flat: global.flatPoints,
			normalize: global.normalizePoints
		};

		var shapes = [];
		for (var j = 0; j < body.fixtures.length; j++) {
			var fixture = body.fixtures[j];
			var shape = exportFixtureParams(fixture);
			shape.source = { width: body.size.width, height: body.size.height };

			if (fixture.isCircle) {
				shape.circle = exportCircle(fixture);
			} else {
				if (global.decompose) {
					shape.points = exportPolygons(fixture.polygons, options);
				} else {
					shape.points = exportPolygons([fixture.hull], options);
				}
			}

			shape.bounds = calcBounds(shape, global.flatPoints);
			shapes.push(shape);
		}

		if (body.concatFixtures) {
			shapes = concatFixtures(shapes, global.flatPoints);
		}

		if (global.useBody) {
			exportedData[body.name] = {
				label: body.label ? body.label : body.name,
				source: options.size,
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

var calcBounds = function(fixture, isFlat) {
	if (fixture.circle)
		return {
			x: fixture.x - fixture.radius,
			y: fixture.y - fixture.radius,
			width: fixture.radius * 2,
			height: fixture.radius * 2
		};

	var maxX = -Infinity;
	var maxY = -Infinity;
	var minX = Infinity;
	var minY = Infinity;

	var len = fixture.points.length;
	for (var i = 0; i < len; i++) {
		var pp = fixture.points[i];
		var pplen = pp.length;
		if (isFlat) {
			for (var j = 0; j < pplen; j += 2) {
				maxX = Math.max(maxX, pp[j]);
				minX = Math.min(minX, pp[j]);

				maxY = Math.max(maxX, pp[j + 1]);
				minY = Math.min(minX, pp[j + 1]);
			}
		} else {
			for (var j = 0; j < pplen; j++) {
				maxX = Math.max(maxX, pp[j][0]);
				minX = Math.min(minX, pp[j][0]);

				maxY = Math.max(maxX, pp[j][1]);
				minY = Math.min(minX, pp[j][1]);
			}
		}
	}

	return {
		x: minX,
		y: minY,
		width: maxX - minX,
		height: maxY - minY
	};
};

var concatFixtures = function(fixtures, flat) {
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

		fixtureA.bounds = calcBounds(fixtureA, flat);
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

var exportPolygons = function(polygons, opts) {
	var result = [];
	for (var i = 0; i < polygons.length; i++) {
		var resultPoly = [];
		for (var j = 0; j < polygons[i].length; j++) {
			var x = polygons[i][j].x;
			var y = polygons[i][j].y;
			if (opts.normalize) {
				x /= opts.size.width;
				y /= opts.size.height;
			}
			if (opts.flat) {
				resultPoly.push(x, y);
			} else {
				resultPoly.push([x, y]);
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
