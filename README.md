MavensMate for Atom (beta)
===============

[![Build Status](https://travis-ci.org/joeferraro/MavensMate-Atom.svg?branch=master)](https://travis-ci.org/joeferraro/MavensMate-Atom)

MavensMate for Atom is a plugin for the Atom text editor that enables Salesforce.com developers to build Salesforce1/Force.com applications inside Atom.

**Note:** MavensMate for Atom is still very much in active development. By installing the plugin at this stage, you are a beta user. You may encounter unexpected behavior, bugs, and general weirdness. Please submit all bugs with specific steps to reproduce: https://github.com/joeferraro/MavensMate-Atom/issues.

**The current beta is OSX-only**

### Installation

To install MavensMate for Atom: 

`Atom > Preferences > Packages > Search for 'MavensMate' > Install`

**Note for OSX users:** MavensMate for Atom uses a node module called `node-keytar`, from the developers of Atom, to securely access the keychain. If you have Xcode installed and have not accepted the Xcode Terms and Conditions, OSX may refuse to install this node module. Simply open Xcode, accept the T&Cs and attempt your MavensMate for Atom install again.

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
