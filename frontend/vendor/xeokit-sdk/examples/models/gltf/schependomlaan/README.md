#### Models

In this example, we're using IFC models from the [Schependomlaan Data Set](https://github.com/openBIMstandards/DataSetSchependomlaan), the ‘Utah Teapot’ for BIM. 

### Pipeline Tools

We'll use these CLI tools to transform IFC into glTF:

* [ifcConvert](http://ifcopenshell.org/ifcconvert.html) to convert IFC files to DAE
* [COLLADA2GLTF](https://github.com/KhronosGroup/COLLADA2GLTF) to convert DAE to glTF
* [gltf-pipeline](https://github.com/AnalyticalGraphicsInc/gltf-pipeline) to optimize glTF

We'll assume that these are installed relative to the current working directory.

### Converting IFC to .DAE

First, convert the Schependomlaan IFC design model to COLLADA:

````
./IfcConvert schependomlaan.ifc  schependomlaan.dae
````

#### Converting .DAE to glTF

Next, convert the COLLADA to glTF 2.0:

````bash
./COLLADA2GLTF/build/COLLADA2GLTF-bin -i schependomlaan.dae -o schependomlaan.gltf
````

#### Optimizing glTF

Optionally, we can do a bunch of optimizations to the glTF, such as compress geometry: 

````
node ./gltf-pipeline/bin/gltf-pipeline.js -i schependomlaan.gltf -o schependomlaan.optimized.gltf
````

