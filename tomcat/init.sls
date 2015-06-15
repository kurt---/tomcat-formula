{% from "tomcat/map.jinja" import tomcat with context %}


include:
  - tomcat.package


ROOT-Webapp:
  cmd.run:
  - name: rm -rf /var/lib/tomcat7/webapps/ROOT
  - onlyif: test -e /var/lib/tomcat7/webapps/ROOT/index.html
  - require:
    - pkg: {{ tomcat.name }}{{ tomcat.version }}