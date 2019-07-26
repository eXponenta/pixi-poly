import {Sprite} from "pixi.js";

const tempPoint = {x : 0, y : 0};

/**
 * Sprite with polygnal interaction cheking.
 * Used texture.shape if existed
 */
export class ShapedSprite extends Sprite {
	
	containsPoint(point) {
		const shape = this._texture.shape;
		if (!shape || !shape.contains) return super.containsPoint(point);
		
		this.worldTransform.applyInverse(point, tempPoint);
		
		const width = this._texture.orig.width;
		const height = this._texture.orig.height;
		let x = tempPoint.x + width * this.anchor.x;
		let y = tempPoint.y + height * this.anchor.y;
		
		if(x < 0 || x > width) return false;
		if(y < 0 || y > height) return false;

		if(shape.anchorAligned){
			x -= width * this.anchor.x;
			y -= height * this.anchor.y;
		}

		return shape.contains(x, y);
	}
}
