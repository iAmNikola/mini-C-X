//OPIS: Postojanje dva atributa sa istim imenom

union Unija {
    int a;
    unsigned a;
};

int main() {
    union Unija a;
    return 1;
}