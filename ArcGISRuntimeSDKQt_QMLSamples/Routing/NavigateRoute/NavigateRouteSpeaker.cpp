#include "NavigateRouteSpeaker.h"

NavigateRouteSpeaker::NavigateRouteSpeaker(QObject* parent):
  QObject(parent)
{
  speaker = new QTextToSpeech(this);
}

NavigateRouteSpeaker::~NavigateRouteSpeaker() = default;

void NavigateRouteSpeaker::textToSpeech(QString text)
{
  speaker->say(text);
}
