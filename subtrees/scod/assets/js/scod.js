function setupDdox()
{
	var els = document.querySelectorAll(".tree-view .package");
	for (var i = 0; i < els.length; ++i)
		els[i].onclick = toggleTree;
	els = document.querySelectorAll(".tree-view.collapsed ul");
	for (var i = 0; i < els.length; ++i)
            els[i].style.display = 'none';
	document.getElementById('symbolSearch').setAttribute('tabindex', '1000');
}

function toggleTree()
{
	var node = this.parentNode;
	node.classList.toggle("collapsed");
	var els = node.children;
	var disp = node.classList.contains('collapsed') ? 'none' : 'block';
	for (var i = 1; i < els.length; ++i)
		els[i].style.display = disp;
	// force redraw
	this.style.display = 'none';
	this.style.display = 'block';
	return false;
}

var searchCounter = 0;
var lastSearchString = "";

function performSymbolSearch(maxlen)
{
	var $ = function (q) { return document.getElementById(q); };
	if (maxlen === 'undefined') maxlen = 26;

	var searchstring = $('symbolSearch').value.toLowerCase();

	if (searchstring == lastSearchString) return;
	lastSearchString = searchstring;

	var scnt = ++searchCounter;
	$('symbolSearchResults').style.display = 'none';
	$('symbolSearchResults').innerHTML = '';
	$('symbolSearch').classList.remove('with_results');

	var terms = searchstring.trim().split(/\s+/);
	if (terms.length == 0 || (terms.length == 1 && terms[0].length < 2)) return;

	var results = [];
	for (var i = 0; i < symbols.length; ++i) {
		var sym = symbols[i];
		var all_match = true;
		for (j in terms)
			if (sym.name.toLowerCase().indexOf(terms[j]) < 0) {
				all_match = false;
				break;
			}
		if (!all_match) continue;

		results.push(sym);
	}

	function compare(a, b) {
		// prefer non-deprecated matches
		var adep = a.attributes.indexOf("deprecated") >= 0;
		var bdep = b.attributes.indexOf("deprecated") >= 0;
		if (adep != bdep) return adep - bdep;

		// normalize the names
		var aname = a.name.toLowerCase();
		var bname = b.name.toLowerCase();

		var anameparts = aname.split(".");
		var bnameparts = bname.split(".");

		var asname = anameparts[anameparts.length-1];
		var bsname = bnameparts[bnameparts.length-1];

		// prefer exact matches
		var aexact = terms.indexOf(asname) >= 0;
		var bexact = terms.indexOf(bsname) >= 0;
		if (aexact != bexact) return bexact - aexact;

		// prefer elements with less nesting
		if (anameparts.length < bnameparts.length) return -1;
		if (anameparts.length > bnameparts.length) return 1;

		// prefer matches with a shorter name
		if (asname.length < bsname.length) return -1;
		if (asname.length > bsname.length) return 1;

		// sort the rest alphabetically
		if (aname < bname) return -1;
		if (aname > bname) return 1;
		return 0;
	}

	results.sort(compare);

	for (i = 0; i < results.length && i < maxlen; i++) {
		sym = results[i];

		var el = document.createElement("li");
		el.classList.add(sym.kind);
		for (var j = 0; j < sym.attributes.length; ++j)
			el.classList.add(sym.attributes[j]);

		var name = sym.name;

		// compute a length limited representation of the full name
		var nameparts = name.split(".");
		var np = nameparts.length-1;
		var shortname = "." + nameparts[np];
		while (np > 0 && nameparts[np-1].length + shortname.length <= maxlen) {
			np--;
			shortname = "." + nameparts[np] + shortname;
		}
		if (np > 0) shortname = ".." + shortname;
		else shortname = shortname.substr(1);

		var link = document.createElement('a');
		link.setAttribute('href', symbolSearchRootDir+sym.path);
		link.setAttribute('title', name);
		link.setAttribute('tabindex', 1001);
		link.textContent = shortname;
		el.appendChild(link);
		$('symbolSearchResults').appendChild(el);
	}

	if (results.length > maxlen) {
		var li = document.createElement('li');
		li.innerHTML = '&hellip;'+(results.length-100)+' additional results';
		$('symbolSearchResults').appendChild(li);
	}

	if (results.length) {
		$('symbolSearchResults').style.display = 'initial';
		$('symbolSearch').classList.add('with_results');
	}
}
