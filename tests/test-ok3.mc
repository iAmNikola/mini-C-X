//OPIS: Castovanje varijable unije

union Unija {
    int a;
};

int main() {
    union Unija u;
    unsigned b;

    u.a = 10;
    b = (unsigned)u.a;
    return 1;
}
