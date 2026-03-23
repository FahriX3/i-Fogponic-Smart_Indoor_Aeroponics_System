//time_utils.cpp
#include "time_utils.h"

bool isTimeInRange(int currentH, int currentM, int startH, int startM, int endH, int endM) {
  unsigned long currentTime = currentH * 60 + currentM;
  unsigned long startTime = startH * 60 + startM;
  unsigned long endTime = endH * 60 + endM;

  if (startTime < endTime) {
    return (currentTime >= startTime && currentTime <= endTime);
  } else {
    return (currentTime >= startTime || currentTime <= endTime);
  }
}

