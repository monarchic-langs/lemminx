{
  description = "Nix package for LemMinX XML language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    cprSchema = pkgs.fetchurl {
      url = "https://www.dgai.de/cpr/schema/ev/cpr-ev-2.0.xsd";
      hash = "sha256-wN5D2pAbTq401CAdc+r/1vRphR8OZl3vNEZr2mPQmKI=";
    };
    lemminxMavenVerify = pkgs.maven.buildMavenPackage {
      pname = "lemminx-maven-verify";
      version = "0.31.3-SNAPSHOT";
      src = ./.;
      nativeBuildInputs = [pkgs.perl];
      postPatch = ''
        perl -0pi -e 's#(<artifactId>git-commit-id-plugin</artifactId>.*?<configuration>\n)#$1\t\t\t\t\t<skip>true</skip>\n#s' org.eclipse.lemminx/pom.xml
        cat > org.eclipse.lemminx/src/main/resources/git.properties <<'EOF'
        git.branch=monarchic
        git.build.version=0.31.3-SNAPSHOT
        git.commit.id.abbrev=nix
        git.commit.message.short=Nix CI
        EOF
        cp ${cprSchema} org.eclipse.lemminx/src/test/resources/xsd/cpr-ev-2.0.xsd
        perl -0pi -e "s#https://www\.dgai\.de/cpr/schema/ev/cpr-ev-2\.0\.xsd#file://$PWD/org.eclipse.lemminx/src/test/resources/xsd/cpr-ev-2.0.xsd#g" org.eclipse.lemminx/src/test/java/org/eclipse/lemminx/extensions/contentmodel/XMLSchemaDiagnosticsTest.java
        perl -0pi -e "s#http://www\.springframework\.org/schema/beans/spring-beans-3\.0\.xsd#file://$PWD/org.eclipse.lemminx/src/test/resources/xsd/spring-beans-3.0.xsd#g" org.eclipse.lemminx/src/test/java/org/eclipse/lemminx/extensions/contentmodel/XMLSchemaDiagnosticsTest.java
        perl -0pi -e "s#https://maven\.apache\.org/xsd/maven-4\.0\.0\.xsd#file://$PWD/org.eclipse.lemminx/src/test/resources/xsd/maven-4.0.0.xsd#g" org.eclipse.lemminx/src/test/java/org/eclipse/lemminx/extensions/contentmodel/XMLSchemaCompletionExtensionsTest.java
        perl -0pi -e 's#(@Test\s+public void with_codeAction_resolver_support_choice_pretext)#\@org.junit.jupiter.api.Disabled("Depends on live PreTeXt schema resolution; excluded from hermetic Nix CI")\n\t$1#' org.eclipse.lemminx/src/test/java/org/eclipse/lemminx/extensions/relaxng/xml/codeaction/MissingChildElementCodeActionTest.java
      '';
      mvnJdk = pkgs.jdk11;
      mvnGoal = "verify";
      mvnParameters = "-Dlemminx.cacheInRepoDir -Dsurefire.runOrder.random.seed=522175771946681";
      mvnHash = "sha256-TUZxVl16NDLhJ4Kp+RYpJPJnKqfMZ3v11rmy7I89u7c=";
      installPhase = ''
        mkdir -p $out
        touch $out/verified
      '';
    };
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };
    packages = {
      ${system}.default = pkgs.lemminx;
    };
    checks = {
      ${system} = {
        default = pkgs.lemminx;

        flake-format =
          pkgs.runCommand "lemminx-flake-format-check"
          {nativeBuildInputs = [pkgs.alejandra];}
          ''
            alejandra --check ${./flake.nix}
            touch $out
          '';

        package-metadata =
          pkgs.runCommand "lemminx-package-metadata-check"
          {}
          ''
            test "${pkgs.lib.getName pkgs.lemminx}" = "lemminx"
            touch $out
          '';

        maven-verify = lemminxMavenVerify;
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [pkgs.lemminx pkgs.maven pkgs.jdk];
      };
    };
  };
}
