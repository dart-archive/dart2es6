class Annotation {
  final String type;
  const Annotation(this.type);
}

const Annotation
    describe = const Annotation('describe'),
    ddescribe = const Annotation('ddescribe'),
    xdescribe = const Annotation('xdescribe'),
    it = const Annotation('it'),
    iit = const Annotation('iit'),
    xit = const Annotation('xit');
