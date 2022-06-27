//OPIS: Vracanje unije iz funkcije i koriscenje njene vrednosti
//RETURN: 10

union Unija {
    int a;
    int b;
    unsigned c;
};

union Unija novaUnija() {
    union Unija nova;
    nova.a = 10;
    return nova;
}

int main() {
    union Unija unija;
    unija.a = 2;
    unija = novaUnija();
    return unija.a;
}
