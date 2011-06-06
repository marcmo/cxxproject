package com.github.cxxproject.eclipse.graphstream.views;

import org.graphstream.ui.layout.springbox.SpringBox;

public final class GoodLayout extends SpringBox {
	public GoodLayout() {
		super(false);
	}

	@Override
	public double getStabilization() {
		if (lastElementCount == countElements()) {
			return Math.max(0.0, 1.0 - 50 * maxMoveLength);
		}
		lastElementCount = countElements();
		return 0.0;
	}

	private int countElements() {
		return nodes.getParticleCount() + edges.size();
	}
	@Override
	public void clear() {
	  super.clear();
	  maxMoveLength = 100;
	}
}