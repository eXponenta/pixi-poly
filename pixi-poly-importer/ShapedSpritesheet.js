import {Spritesheet} from "pixi.js";
import {CompoundShape} from "./CompoundShape";

export class ShapedSpritesheet extends Spritesheet {
	/**
	 * Create shaped spritesheet from Spritesheet and shapeData.
	 * Add prop 'shape : CompoundShape ' to textures when label of shape equal texture's key
	 * @param {Spritesheet} sheet
	 * @param {*} shapeData
	 */
	static fromSpritesheet(sheet, shapeData) {
		if (!shapeData || shapeData.tag !== "pixi_polygon_points") {
			return;
		}
		const ret = Object.create(ShapedSpritesheet.prototype);
		Object.assign(ret, sheet);

		ret.shapeData = shapeData;

		let shapes;
		if (shapeData.format.body) {
			const name = ret.data.meta.image.split(".")[0];
			const body = shapeData[name];
			if (!body) {
				throw new Error(`Body '${name} can't found on shape data`);
			}
			shapes = body.shapes;
		} else {
			shapes = shapeData.shapes;
		}

		const shapeMap = shapes.reduce((acc, e) => {
			acc[e.label] = e;
			return acc;
		}, {});

		for (let key in shapeMap) {
			const s = shapeMap[key];
			const t = ret.textures[key];
			if (!t) {
				continue;
			}
			const p = CompoundShape.parse(s, 1, shapeData.format.normalized);
			p.alignToTexture(t);
			t.shape = p;
		}

		return ret;
	}
}
