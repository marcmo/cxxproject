package com.github.cxxproject.eclipse.graphstream.views;

public class ZoomInfo {

  private static final int DELTA = 10;
  int fBorder = 40;
  public void incZoom() {
    fBorder-=DELTA;
  }
  public void decZoom() {
    fBorder+=DELTA;
  }
  public int getBorder() {
    return fBorder;
  }
}
