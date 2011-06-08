package com.github.cxxproject.eclipse.graphstream.views;

import java.util.HashSet;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Display;
import org.graphstream.graph.Element;
import org.graphstream.ui.geom.Point3;
import org.graphstream.ui.graphicGraph.GraphicEdge;
import org.graphstream.ui.graphicGraph.GraphicGraph;
import org.graphstream.ui.graphicGraph.GraphicNode;
import org.graphstream.ui.graphicGraph.StyleGroup;

final class GraphPaintListener implements PaintListener {
  private final GraphicGraph fGraph;
  private Color fColor;
  private double ratio;
  private double dx;
  private double dy;
  private float xRatio;
  private float yRatio;
  private ZoomInfo fZoomInfo;

  GraphPaintListener(GraphicGraph g, ZoomInfo zoomInfo) {
    fGraph = g;
    fZoomInfo = zoomInfo;
  }

  @Override
  public void paintControl(PaintEvent e) {
    Canvas c = (Canvas) e.widget;

    setupSzene(fGraph, c, e.gc);
    
    e.gc.setAntialias(SWT.ON);
    for (HashSet<StyleGroup> groups : fGraph.getStyleGroups().zIndex()) {
      for (StyleGroup group : groups) {
        renderGroup(e.gc, group);
      }
    }
  }

  private void setupSzene(GraphicGraph fGraph2, Canvas c, GC gc) {
    Point3 min = fGraph.getMinPos();
    Point3 max = fGraph.getMaxPos();
    fGraph.computeBounds();
    min = fGraph.getMinPos();
    max = fGraph.getMaxPos();
    double graphWidth = max.x - min.x;
    double graphHeight = max.y - min.y;
    double widgetWidth = c.getSize().x;
    double widgetHeight = c.getSize().y;

    int BORDER = fZoomInfo.getBorder();
    xRatio = (float) (Math.max(0, widgetWidth - BORDER) / graphWidth);
    yRatio = (float) (Math.max(0, widgetHeight - BORDER) / graphHeight);
    ratio = Math.min(xRatio, yRatio);
    dx = widgetWidth / 2 - ratio * (min.x + graphWidth / 2);
    dy = widgetHeight / 2 - ratio * (min.y + graphHeight / 2);
  }

  Point getPos(GraphicNode gn) {
    int xPos = (int) (dx + ratio * (gn.x));
    int yPos = (int) (dy + ratio * (gn.y));
    return new Point(xPos, yPos);
  }

  private void renderGroup(GC gc, StyleGroup group) {
    java.awt.Color c = group.getFillColor(0);
    activateStyle(c, gc);
    switch (group.getType()) {
    case NODE:
      for (Element e : group.bulkElements()) {
        GraphicNode gn = (GraphicNode) e;
        Point p = getPos(gn);
        int WIDTH = 10;
        gc.setForeground(Display.getDefault().getSystemColor(SWT.COLOR_BLACK));
        gc.fillOval(p.x - WIDTH / 2, p.y - WIDTH / 2, WIDTH, WIDTH);
        gc.drawOval(p.x - WIDTH / 2, p.y - WIDTH / 2, WIDTH, WIDTH);
        /*
        String label = (String) gn.getAttribute("ui.label");
        if (label != null) {
          Point labelPos = new Point(p.x + 5, p.y + 5);
          gc.drawText(label, labelPos.x, labelPos.y, true);
        }
        */
      }
      break;
    case EDGE:
      for (Element e : group.bulkElements()) {
        GraphicEdge edge = (GraphicEdge) e;
        GraphicNode n0 = (GraphicNode) edge.getNode0();
        GraphicNode n1 = (GraphicNode) edge.getNode1();
        Point p0 = getPos(n0);
        Point p1 = getPos(n1);
        gc.drawLine(p0.x, p0.y, p1.x, p1.y);
      }
      break;
    case SPRITE:
      break;
    case GRAPH:
      break;
    default:
    }
    if (fColor != null) {
      fColor.dispose();
      fColor = null;
    }

  }

  private void activateStyle(java.awt.Color c, GC gc) {
    fColor = new Color(Display.getDefault(), c.getRed(), c.getGreen(), c.getBlue());
    gc.setForeground(fColor);
    gc.setBackground(fColor);
  }
}
