# hAbitti

Shell-skripti, joka on suunniteltu luomaan muokattu versio Abitista, suomalaisissa kouluissa käytettävästä koeympäristöohjelmistosta, korotetuilla oikeuksilla ja internet-yhteydellä.

## Vaatimukset

Linux-pohjainen käyttöjärjestelmä (testattu Ubuntu 20.04.5:llä)

Xorriso asennettuna haluamasi pakettienhallinnan kautta

Pääsy sudo-oikeuksiin tai root-tiliin

## Käyttö

Kloonaa arkisto käyttämällä `git clone https://github.com/Trimpsuz/habitti`

Aja skripti: Suorita skripti root-oikeuksilla seuraavalla komennolla: `sudo ./habittiBuilder.sh`

Pura haluamasi Abitti-version `filesystem.squashfs` hakemistoon

Jos debian live -kuvaa ei ole ladattu, skripti lataa sen automaattisesti puolestasi

---

### Vastuuvapauslauseke

Ohjelmisto toimitetaan sellaisenaan ilman minkäänlaisia takuita tai vakuutuksia. Se on tarkoitettu vain opetuskäyttöön, eikä sitä tule käyttää oikeassa koeympäristössä. Skriptin tekemät muutokset eivät välttämättä sovellu kaikkiin käyttötarkoituksiin. Lue lisätietoja [lisenssi](LICENSE) tiedostosta.  