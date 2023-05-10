var count = Object.keys(typefaces.typeface).length;
//alert(count);
var container = document.getElementById("typeview_TypefaceDisplayContainer");

const specimenContainer = document.getElementById("typeview_SpecimenContainer");

function typeview_UpdateFontFamily(typefaceName) {
  specimenContainer.style.fontFamily = typefaceName;
}

function typeview_InvokeListOfNames() {
  for (var i = 0; i < count; i++) {
    //console.log(typefaces.typeface[i]);
    var type = typefaces.typeface[i];
    var typefaceElement =
      '<div class="typeview_Typeface" ' +
      "onclick=\"typeview_UpdateFontFamily('" +
      type.literal +
      "');\" " +
      'id="' +
      type.name +
      '">' +
      type.literal +
      "</div></div>";

    container.innerHTML += typefaceElement;
  }
}

// function typeview_InvokeList() {
//   for (var i = 0; i < count; i++) {
//     //console.log(typefaces.typeface[i]);
//     var type = typefaces.typeface[i];
//     var typefaceElement =
//       '<div class="typeview_Typeface" ' +
//       "onmouseover=\"document.getElementById('" +
//       type.name +
//       "').style.fontFamily='" +
//       type.literal +
//       "';\" " +
//       "onmouseout=\"document.getElementById('" +
//       type.name +
//       "').style.fontFamily='';\"><div id=\"" +
//       type.name +
//       '" class="typeview_Typeface">' +
//       type.literal +
//       "</div></div>";

//     container.innerHTML += typefaceElement;
//   }
// }

// function typeview_UpdateFontSize() {
//   const typefaces = document.getElementsByClassName("typeview_Typeface");
//   const slider = document.getElementById("typeview_TypefaceSizeSlider");

//   slider.addEventListener("input", (e) => {
//     Array.from(typefaces).forEach((typeface) => {
//       typeface.style.fontSize = e.target.value + "pt";
//     });
//   });
// }

function typeview_FilterTypeface() {
  // Declare variables
  var typeview_SearchBox,
    filter,
    typeview_TypefaceDisplayContainer,
    typeview_DisplayArea;
  typeview_SearchBox = document.getElementById("typeview_SearchBox");
  filter = typeview_SearchBox.value.toUpperCase();
  typeview_TypefaceDisplayContainer = document.getElementById(
    "typeview_TypefaceDisplayContainer"
  );
  typeview_DisplayArea =
    typeview_TypefaceDisplayContainer.getElementsByClassName(
      "typeview_Typeface"
    );

  // Loop through all list items, and hide those who don't match the search query
  for (let i = 0; i < typeview_DisplayArea.length; i++) {
    let a =
      typeview_DisplayArea[i].getElementsByClassName("typeview_Typeface")[0];
    let txtValue = a.textContent || a.innerText;

    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      typeview_DisplayArea[i].style.display = "";
    } else {
      typeview_DisplayArea[i].style.display = "none";
    }
  }
}
