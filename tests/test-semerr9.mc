//OPIS: Vracanje drugog tipa varijable unije iz funkcije

union Unija {
    int a;
    unsigned b;
};

int funkcija(){
    union Unija u;
    return u.b;
}

int main() {
    return funkcija();
}