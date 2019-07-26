import {Polygon, TextureMatrix, Texture, Sprite} from "pixi.js";

const tmpPoint = {x: 0, y: 0};

function applyInvMatrix(texture, point, normalized) {
	if (!normalized) {
		point.x /= texture.baseTexture.width;
		point.y /= texture.baseTexture.height;
	}
	texture.uvMatrix.mapCoord.applyInverse(point, point);
	point.x *= texture.orig.width;
	point.y *= texture.orig.height;

	return point;
}

function applyMatrix(texture, point, normalized) {
	point.x /= texture.orig.width;
	point.y /= texture.orig.height;
	texture.uvMatrix.mapCoord.apply(point, point);
	if (!normalized) {
		point.x *= texture.baseTexture.width;
		point.y *= texture.baseTexture.height;
	}

	return point;
}

export class CompoundShape {
	/**
	 * Multiple shape container with point transforming feature.
	 * @param {Array<Polygon>} shapes - stored shapes
	 * @param {boolean} normalized - must be marked when polygons points is normalised of Atlas space
	 */
	constructor(shapes, normalized = false) {
		this.shapes = shapes;
		this.anchorAligned = false;
		this._offset = {x: 0, y: 0};
		this._lastSimpleTexture = undefined;
		this._normalized = normalized;
	}

	/**
	 * Checks point intersection with all stored shapes
	 * @param {number} x
	 * @param {number} y
	 */
	contains(x, y) {
		if (!this.shapes || this.shapes.length === 0) return false;

		const count = this.shapes.length;
		for (let i = 0; i < count; i++) {
			if (this.shapes[i].contains(x, y)) return true;
		}
		return false;
	}

	/**
	 * Trasnsform shapes from Attlas to texture space
	 * Used for transforming polygonal data from spritesheet
	 * @param {Texture} texture
	 */
	alignToTexture(texture) {
		this.alignToSprite({texture: texture}, true);
	}

	/**
	 * Trasnsform point from Attlas to sprite space include anchor point
	 * Used for transforming polygonal data from spritesheet with anchoring
	 * @param {Sprite} sprite
	 * @param {boolean} ignoreAnchor - ignore anchor when trnasforming, works as alignToTexture
	 */
	alignToSprite(sprite, ignoreAnchor = false) {
		const texture = sprite.texture;
		if (!texture.uvMatrix) {
			texture.uvMatrix = new TextureMatrix(texture, 0.0);
			texture.uvMatrix.update(true);
		} else {
			texture.uvMatrix.update();
		}

		const orig = texture.orig;
		const anchor = sprite.anchor;

		for (let p of this.shapes) {
			for (let i = 0; i < p.points.length; i += 2) {

				tmpPoint.x = p.points[i] + this._offset.x;
				tmpPoint.y = p.points[i + 1] + this._offset.y;

				if (this._lastSimpleTexture) {
					applyMatrix( this._lastSimpleTexture, tmpPoint, this._normalized );
				}
				
				applyInvMatrix(texture, tmpPoint, this._normalized);

				if (!ignoreAnchor) {
					tmpPoint.x -= anchor.x * orig.width;
					tmpPoint.y -= anchor.y * orig.height;
				 
				}
				p.points[i] = tmpPoint.x;
				p.points[i + 1] = tmpPoint.y;
			}
		}

		let matrix;
		if (this._lastSimpleTexture) {
			matrix = this._lastSimpleTexture.uvMatrix.mapCoord;
			matrix.copyFrom(texture.uvMatrix.mapCoord);
		} else {
			matrix = texture.uvMatrix.mapCoord.clone();
		}

		this._lastSimpleTexture = {
			baseTexture: {
				width: texture.baseTexture.width,
				height: texture.baseTexture.height
			},
			orig: texture.orig.clone(),
			uvMatrix: {
				mapCoord: matrix
			}
		};

		this._offset.x = ignoreAnchor ? 0 : anchor.x * orig.width;
		this._offset.y = ignoreAnchor ? 0 : anchor.y * orig.height;

		this.anchorAligned = !ignoreAnchor;
	}

	/**
	 * Parse shape from points data
	 * @param {Array<number> | Array<Array<number>> | { points : Array<Array<number>> }} shapeData
	 * @param {number} scale - scaling points when parsing (normalization prevent this)
	 * @param {boolean} normalized - must be marked when polygons points is normalised of Atlas space
	 */
	static parse(shapeData, scale = 1, normalized = false) {
		let points;

		if (Array.isArray(shapeData)) points = shapeData;
		else if (shapeData.points) points = shapeData.points;

		if (!Array.isArray(points)) throw Error("Points isn't array!");

		if (!Array.isArray(points[0]) || points.length === 2) points = [points];

		if (points[0].length === 2) points = points.map(p => p.flat());

		if (scale && scale !== 1 && !normalized) {
			points = points.map(p => {
				return p.map(el => el * scale);
			});
		}

		const polygons = points.map(p => new Polygon(p));

		return new this(polygons, normalized);
	}
}
