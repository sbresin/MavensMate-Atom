MavensMate for Atom (beta)
===============

[![Build Status](https://travis-ci.org/joeferraro/MavensMate-Atom.svg?branch=master)](https://travis-ci.org/joeferraro/MavensMate-Atom)

MavensMate for Atom is a plugin for the Atom text editor that enables Salesforce.com developers to build Salesforce1/Force.com applications inside Atom.

**Note:** MavensMate for Atom is still very much in active development. By installing the plugin at this stage, you are a beta user. You may encounter unexpected behavior, bugs, and general weirdness. Please submit all bugs with specific steps to reproduce: https://github.com/joeferraro/MavensMate-Atom/issues.

### Installation

#### `node-keytar` Dependency (optional)

MavensMate for Atom includes an optional dependency, `node-keytar`, from the developers of Atom. `node-keytar` enables MavensMate to securely access the system keychain. The prerequisite for installing `node-keytar` varies by platform:

##### OSX

If you have Xcode installed and have not accepted the Xcode Terms and Conditions, OSX may refuse to install `node-keytar`. Simply open Xcode, accept the T&Cs and attempt your MavensMate for Atom install again.

##### Windows

You should have Visual Studio Express for Desktop installed in order to properly install `node-keytar`: http://www.visualstudio.com/downloads/download-visual-studio-vs#d-express-windows-desktop

##### Linux

You should run `sudo apt-get install libgnome-keyring-dev` before installing MavensMate for Atom.

#### Installing MavensMate for Atom Package

`Open Atom > Preferences/Settings > Packages > Search for "MavensMate" > Install`

**Note for Windows/Linux users:** We've performed the bulk of our testing on OSX. If you encounter issues, you are encouraged to submit a bug report.

![Alt Text](http://i.imgur.com/RiBsW0N.gif?1 "Install")

### Configuration

To configure MavensMate for Atom:

`Atom > Preferences > Packages > Select MavensMate package`

![Alt Text](http://i.imgur.com/NmapjKE.gif?1 "Configure")

### Create a Project

To create your first MavensMate for Atom project:

1. Be sure to configure your `mm workspace` (see Configuration)
2. MavensMate > New Project
 
![Alt Text](http://i.imgur.com/SCDknHg.gif?1 "New Project")

### Run MavensMate Commands

To run MavensMate commands, use the Atom command palette. On OSX: `command + shift + p`

![Alt Text](http://i.imgur.com/IuYO4pU.gif?1 "Commands")
