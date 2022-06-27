//OPIS: Dodela drugog tipa vrednosti varijabli unije

union Unija {
    int a;
    unsigned b;
};

int main() {
    union Unija x;
    union Unija y;

    y.b = 5u;
    x.a = y.b;

    return 1;
}